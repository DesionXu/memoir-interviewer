#!/usr/bin/env node
// ============================================
// 网页端（memoir.html）集成测试：模拟鸿蒙桥接环境，验证核心流程
//
// 依赖：jsdom（建议安装到临时目录：npm i jsdom）
// 运行：先启动后端代理（PORT 可自定义）：
//   DEEPSEEK_API_KEY=sk-xxx PORT=3462 node server.js &
//   node --experimental-vm-modules scripts/test-web-integration.js [代理端口，默认3462]
// 测试项：初始渲染 / 桥接聊天 / 空正文自动重试 / 回忆录续写与分页 / 原生语音流程
// ============================================
const path = require('path');
const { JSDOM } = require('jsdom');

const HTML = path.join(__dirname, '..', 'memoir.html');
const PORT = process.argv[2] || '3462';

// ===== 模拟鸿蒙原生桥 =====
const bridge = {
  chatCalls: [],
  chatImpl: [],   // 可配置的返回序列（函数数组）
  listenStartCalls: 0,
  listenStopCalls: 0,
  speakTexts: [],
  chat(messagesJson, maxTokens, temperature, callbackId) {
    this.chatCalls.push({ messages: JSON.parse(messagesJson), maxTokens, temperature, callbackId });
    const fn = this.chatImpl.shift();
    const data = fn();
    setTimeout(() => {
      const w = dom.window;
      if (data.error) {
        w.__bridgeReject(callbackId, data.error);
      } else {
        w.__bridgeResolve(callbackId, JSON.stringify(data));
      }
    }, 10);
  },
  speak(text) { this.speakTexts.push(text); },
  listenStart() { this.listenStartCalls++; },
  listenStop() {
    this.listenStopCalls++;
    // 模拟原生端识别结束后的 onComplete → __bridgeOnAsrEnd 回调
    setTimeout(() => { dom.window.__bridgeOnAsrEnd(); }, 20);
  },
  goHome() { this.goHomeCalls = (this.goHomeCalls || 0) + 1; }
};

let dom;
let failures = 0;

function loadPage() {
  return new Promise((resolve, reject) => {
    JSDOM.fromFile(HTML, {
      url: 'http://localhost/memoir.html',
      runScripts: 'dangerously',
      pretendToBeVisual: true,
      beforeParse(window) {
        window.HarmonyBridge = bridge;
        window.fetch = async (url, opts) => {
          return fetch(String(url).replace('http://localhost', 'http://localhost:' + PORT), opts);
        };
      }
    }).then(d => {
      dom = d;
      setTimeout(() => resolve(d.window), 100);
    }).catch(reject);
  });
}

function ok(name, cond) {
  console.log((cond ? '✅' : '❌') + ' ' + name);
  if (!cond) failures++;
}

async function main() {
  const w = await loadPage();

  // ===== 1. 初始渲染 =====
  ok('初始显示开场白', w.document.getElementById('chatBox').textContent.includes('回忆录访谈员'));
  ok('语音输入可用（鸿蒙桥接探测）', w.document.getElementById('micBtn').style.display !== 'none');
  ok('语音输入开关为开', w.document.getElementById('voiceInputState').textContent === '开');
  ok('语音输出未被误禁用（桥接朗读场景）', !w.document.getElementById('voiceOutputToggle').disabled
    && w.document.getElementById('voiceOutputToggle').checked);

  // ===== 2. 聊天（桥接成功路径）=====
  bridge.chatImpl = [() => ({ choices: [{ message: { content: '您小时候住在哪里呀？' }, finish_reason: 'stop' }] })];
  w.document.getElementById('userInput').value = '我小时候住在乡下';
  await w.sendMessage();
  await new Promise(r => setTimeout(r, 60));
  ok('聊天：AI 回复已渲染', w.document.getElementById('chatBox').textContent.includes('您小时候住在哪里呀'));
  ok('聊天：桥接收到正确参数', bridge.chatCalls.length === 1 && bridge.chatCalls[0].maxTokens === 1024);
  ok('聊天：输入框已清空', w.document.getElementById('userInput').value === '');
  ok('聊天：朗读已触发', bridge.speakTexts.includes('您小时候住在哪里呀？'));

  // ===== 3. 空正文自动重试（v4-pro 推理占满预算场景）=====
  bridge.chatCalls = [];
  bridge.chatImpl = [
    () => ({ choices: [{ message: { content: '' }, finish_reason: 'length' }] }),
    () => ({ choices: [{ message: { content: '槐树下夏天很凉快吧？' }, finish_reason: 'stop' }] })
  ];
  w.document.getElementById('userInput').value = '门口有棵大槐树';
  await w.sendMessage();
  await new Promise(r => setTimeout(r, 80));
  ok('重试：共调用两次桥接', bridge.chatCalls.length === 2);
  ok('重试：第二次预算加倍(2048)', bridge.chatCalls[1].maxTokens === 2048);
  ok('重试：最终回复正常显示', w.document.getElementById('chatBox').textContent.includes('槐树下夏天很凉快吧'));

  // ===== 4. 生成回忆录（截断续写 + 分页页码）=====
  bridge.chatCalls = [];
  bridge.chatImpl = [
    () => ({ choices: [{ message: { content: '槐树下的记忆\n\n【开篇概要】\n老人住在江西农村。\n\n【目录】\n第一章 童年与大槐树\n第二章 县城学徒\n\n【正文】\n第一章 童年与大槐树\n老人小时候住在农村，门口有一棵大槐树，夏天在树下乘凉，' }, finish_reason: 'length' }] }),
    () => ({ choices: [{ message: { content: '母亲做的饭很香。\n\n第二章 县城学徒\n十八岁进机械厂当学徒，学了三年钳工。' }, finish_reason: 'stop' }] })
  ];
  await w.generateMemoir();
  await new Promise(r => setTimeout(r, 100));
  const book = w.document.getElementById('memoryBook').value;
  ok('回忆录：两次续写拼接完整', book.includes('母亲做的饭很香') && book.includes('县城学徒'));
  ok('回忆录：含页码', /— 第 \d+ 页 —/.test(book));
  ok('回忆录：章节结构保留', book.includes('第一章 童年与大槐树'));
  ok('回忆录：底部面板已打开', w.document.getElementById('memoirOverlay').classList.contains('open'));
  // 关闭面板
  w.closeMemoirPanel();
  ok('回忆录：面板可关闭', !w.document.getElementById('memoirOverlay').classList.contains('open'));
  w.openMemoirPanel();
  ok('回忆录：面板可重新打开', w.document.getElementById('memoirOverlay').classList.contains('open'));

  // ===== 5. 原生语音输入流程 =====
  bridge.listenStartCalls = 0;
  w.startListening();
  ok('语音：listenStart 已调用', bridge.listenStartCalls === 1);
  ok('语音：麦克风进入收音状态', w.document.getElementById('micBtn').textContent.includes('🔴'));
  w.__bridgeOnAsr('我小时候', '住在乡下');
  ok('语音：识别结果实时写入输入框', w.document.getElementById('userInput').value.includes('我小时候住在乡下'));
  bridge.chatCalls = [];
  bridge.chatImpl = [() => ({ choices: [{ message: { content: '乡下好玩吗？' }, finish_reason: 'stop' }] })];
  w.stopListeningAndSend();
  await new Promise(r => setTimeout(r, 100));
  ok('语音：listenStop 已调用', bridge.listenStopCalls === 1);
  ok('语音：识别内容已自动发送', bridge.chatCalls.length === 1
    && bridge.chatCalls[0].messages.some(m => m.content.includes('我小时候住在乡下')));
  ok('语音：收音状态已结束', w.document.getElementById('micBtn').textContent.includes('🎤'));

  // ===== 6. 语音开关行为 =====
  w.document.getElementById('voiceInputToggle').click();
  ok('开关：语音输入关闭后麦克风隐藏', w.document.getElementById('micBtn').style.display === 'none');
  w.document.getElementById('voiceInputToggle').click();
  ok('开关：语音输入重新开启后麦克风显示', w.document.getElementById('micBtn').style.display !== 'none');

  w.document.getElementById('voiceOutputToggle').click();
  const speakCountBefore = bridge.speakTexts.length;
  bridge.chatImpl = [() => ({ choices: [{ message: { content: '静默测试' }, finish_reason: 'stop' }] })];
  w.document.getElementById('userInput').value = '测试';
  await w.sendMessage();
  await new Promise(r => setTimeout(r, 60));
  ok('开关：语音输出关闭后不再朗读', bridge.speakTexts.length === speakCountBefore);
  w.document.getElementById('voiceOutputToggle').click();
  ok('开关：语音输出重新开启', w.document.getElementById('voiceOutputState').textContent === '开');

  console.log(failures === 0 ? '\n🎉 全部测试通过' : `\n❌ ${failures} 项失败`);
  process.exit(failures ? 1 : 0);
}

main().catch(e => { console.error('测试异常:', e); process.exit(1); });
