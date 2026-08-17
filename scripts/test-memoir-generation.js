#!/usr/bin/env node
// ============================================
// 回忆录生成 端到端测试
// 前提：先启动后端代理 server.js（DEEPSEEK_API_KEY 从 config.js/.env 读取）
//   DEEPSEEK_API_KEY=sk-xxx PORT=3461 node server.js &
// 用法：node scripts/test-memoir-generation.js [代理地址，默认 http://localhost:3461]
// 校验：标题/开篇概要/目录/正文四要素、章节结构、完整收尾（finish_reason=stop）
// ============================================
const BASE = process.argv[2] || 'http://localhost:3461';

const MEMOIR_SYSTEM_PROMPT = `你是一位耐心的回忆录整理者，帮助老人把口述的人生故事整理成留给后人的回忆录。
请仔细阅读下面的访谈对话素材，以老人讲述的内容为唯一依据，撰写一部完整的回忆录。

写作要求：
1. 以第三人称叙述，把受访者称为"老人"或"他/她"，像一位长辈把一生的故事讲给子孙后代听。
2. 语气朴实、亲切、温暖，像家常话娓娓道来；不要模仿史书或历史传记的腔调，不要过度渲染。
3. 严格依据素材：只写老人在访谈中真实讲到的内容，尽量保留原话里的细节和意思，不添油加醋、不虚构情节、不做文学化夸张。
4. 结构依次为（以下四个标记必须原样输出）：
   ① 标题：拟一个简单朴实的标题（单独一行）。
   ② 【开篇概要】：一段话，简要概括老人的人生经历。
   ③ 【目录】：按时间顺序列出各章标题，每行一章，格式如"第一章 童年岁月"。
   ④ 【正文】：按时间线分章展开，每章以"第X章 章名"开头，再写若干段落。
5. 完整性优先：正文要覆盖素材中提到的各个时期和主要经历，不要省略、不要草草收尾；篇幅以把事情讲完整为准，不设上限。
6. 只输出纯文本，不要使用任何 Markdown 符号（不要#、*、-、>等标记），不要写页码。`;

const conversation = [
  { role: 'assistant', content: '您好呀，可以跟我聊聊您小时候住的地方吗？' },
  { role: 'user', content: '我小时候住在江西农村，家门口有一棵大槐树，夏天在树下乘凉。父亲是木匠，家里穷，但母亲总是把饭做得很香。' },
  { role: 'assistant', content: '大槐树下的夏天，真让人向往。后来呢，您是怎么离开家乡的？' },
  { role: 'user', content: '十八岁那年村里招工，我去了县城的机械厂当学徒，跟着师傅学了三年钳工。厂里食堂的馒头二两一个，我一次能吃四个。' },
  { role: 'assistant', content: '当学徒的日子一定很辛苦。后来在厂里遇到您的爱人了吗？' },
  { role: 'user', content: '对，她当时在厂里的托儿所当阿姨，我们经人介绍认识的。七九年结的婚，厂里分了一间平房，只有十四平方，我们自己拉了个小院种菜。' },
  { role: 'assistant', content: '十四平方的小家，很温馨。孩子是什么时候出生的？' },
  { role: 'user', content: '八一年生的儿子。那几年厂子效益好，我评上了五级钳工，工资从三十六块涨到五十八块。儿子读书很争气，后来考上了大学。' },
  { role: 'assistant', content: '真不容易。您是什么时候退休的？退休后的日子过得怎么样？' },
  { role: 'user', content: '零五年退休，退休金不多，但和老伴每天早上去公园打太极。前年老伴走了，儿子接我到他家住，可我还是想念老家的槐树。' }
];

async function chat(messages, maxTokens, temperature) {
  const res = await fetch(BASE + '/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ messages, max_tokens: maxTokens, temperature })
  });
  if (!res.ok) throw new Error('代理返回 ' + res.status);
  return res.json();
}

(async () => {
  const messages = [{ role: 'system', content: MEMOIR_SYSTEM_PROMPT }, ...conversation,
    { role: 'user', content: '请根据以上全部访谈对话素材，撰写完整的回忆录。' }];
  const data = await chat(messages, 8192, 0.7);
  const choice = data.choices && data.choices[0];
  const text = ((choice && choice.message.content) || '').trim();
  const chapters = (text.match(/第[一二三四五六七八九十0-9]+章/g) || []).length;

  const checks = [
    ['完成收尾(finish_reason=stop)', choice && choice.finish_reason === 'stop'],
    ['正文非空', text.length > 500],
    ['含【开篇概要】', text.includes('【开篇概要】')],
    ['含【目录】', text.includes('【目录】')],
    ['含【正文】', text.includes('【正文】')],
    ['有章节标题', chapters >= 4]
  ];
  let failed = 0;
  for (const [name, ok] of checks) {
    console.log((ok ? '✅' : '❌') + ' ' + name);
    if (!ok) failed++;
  }
  console.log('正文总字数:', text.length, '| 章节标题数:', chapters);
  console.log('--- 输出前 300 字 ---');
  console.log(text.slice(0, 300));
  process.exit(failed ? 1 : 0);
})().catch(e => { console.error('❌ 测试失败:', e.message); process.exit(1); });
