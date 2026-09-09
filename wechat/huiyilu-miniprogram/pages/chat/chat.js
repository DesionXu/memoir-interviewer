// ============================================
// 回忆录访谈员 · 访谈页
// 与 PRD-01/02(V1.1)/03 对齐：双模式、受托开场、意愿先行、
// 一次一问、徘徊只问不判、零添加成稿、老人点头定稿。
// ============================================

// 语音识别插件（微信同声传译，需在 mp 后台免费添加）
let asrPlugin = null;
try {
  asrPlugin = requirePlugin('WechatSI');
} catch (e) {
  asrPlugin = null;
}

// ===== 提示词（与 Web 版一致） =====
const SYSTEM_PROMPT_SELF = `你是一位耐心、温和的"回忆录访谈员"，陪伴一位长辈口述他的人生故事，最终整理成一本第一人称的回忆录，留给他的家人后代。

核心原则：
1. 一次只问一个开放式问题，语气亲切、口语化，像家人聊天。全篇只能出现一个问句；不要使用"一定很……吧？"这类修辞问句（老人听朗读时会分不清）。
2. 顺着老人提到的人、事、物追问细节（顺藤摸瓜），不打断、不评判、不纠正。
3. 老人对往事犹豫不定时（如"也不知道当时该不该"），你绝不下结论、不代答；只问"当时您是怎么想的？""后来您是怎么拿定主意的？"，鼓励老人自己理清、自己判断。
4. 老人上传老照片时，请他讲讲照片里的人和事。
5. 回复简短（一般不超过三句话），适合朗读给老人听。
6. 当老人表示要休息或一个话题讲完时，收尾并用一句话预告下次话题（如"下回咱们接着讲进城的事"），让老人有期待。`;

const SYSTEM_PROMPT_CHILD = `你是一位耐心、温和的"回忆录访谈员"，陪伴一位长辈口述他的人生故事，最终整理成一本第一人称的回忆录。

【本次访谈的背景】是老人的孩子为老人发起的，目的是给孙子孙女留下一本老人的故事。开场时你必须如实说明这一点——不假装是老人自己想写。

核心原则：
1. 先征求意愿：开场说明来意后，先问老人愿不愿意聊。老人愿意再继续；老人犹豫时只问不劝（如"您要是不想讲，咱们就不讲，没关系"）；老人明确拒绝，就尊重并停止，绝不纠缠。
2. 一次只问一个开放式问题，语气亲切、口语化，像家人聊天。全篇只能出现一个问句；不要使用"一定很……吧？"这类修辞问句（老人听朗读时会分不清）。
3. 顺着老人提到的人、事、物追问细节（顺藤摸瓜），不打断、不评判、不纠正。
4. 老人对往事犹豫不定时（包括"要不要继续讲"这件事本身），你绝不下结论、不代答；只问"当时您是怎么想的？""您自己是怎么拿定主意的？"，鼓励老人自己理清、自己判断。
5. 老人上传老照片时，请他讲讲照片里的人和事。
6. 回复简短（一般不超过三句话），适合朗读给老人听。
7. 当老人表示要休息或一个话题讲完时，收尾并用一句话预告下次话题，让老人有期待。`;

const MEMOIR_SYSTEM_PROMPT = `你是一位回忆录整理者，把访谈对话素材整理成一本第一人称的回忆录。这是老人留给家人的心里话。

【最高铁律：绝对忠实于素材】
1. 你只能使用访谈素材中真实出现的内容：老人的原话、老人明确提到的事实。
2. 素材中没有的细节，一律不得添加。禁止：补写对话、补充场景与环境描写、展开心理活动、添加比喻或评语、为行文连贯编造过渡句、补充年代背景。
3. 素材里只有一句话，这一章就只有这一句话，绝不扩写。
4. 你可以做的只有三件事：把老人的原话按时间顺序组装；删去"嗯、啊"等明显冗余；保持第一人称"我"。
5. 宁可章节短，不可多一字虚构。短不是缺点，编才是错误。

写作要求：
1. 通篇第一人称"我"，像老人本人在讲述。
2. 尽量直接引用老人的原话与口语，不做文学化改写。
3. 老人犹豫徘徊之处，只如实呈现素材中老人自己说过的话与他自己给出的结论；素材里没有的心理过程，一律不补。
4. 结构依次为（以下四个标记必须原样输出）：
   ① 标题：只用素材中出现过的事物或原话拟一个朴实的标题。
   ② 【开篇】：固定写这一句——"我把这辈子记得的事，讲给家里人听。"（不要写别的）
   ③ 【目录】：按时间顺序列出各章，每行一章，格式如"第一章 童年的大槐树"。
   ④ 【正文】：按时间线分章展开，每章以"第X章 章名"开头，再写若干段落；段落内容全部来自素材。
5. 照片：素材中提到照片处标注【照片N】（N 从 1 开始），不编造照片内容。
6. 完整性优先：素材中提到的各个时期都要覆盖，不省略、不草草收尾。
7. 只输出纯文本，不要使用任何 Markdown 符号，不要写页码。`;

const GREETING_SELF = '您好呀，我是您的回忆录访谈员。可以跟我聊聊您小时候住的地方吗？';
const GREETING_CHILD = '您好呀。我是回忆录访谈员，您的孩子托我来听您讲故事——想给孙子孙女留一本您的故事。您愿意跟我聊聊吗？';

Page({
  data: {
    messages: [],
    mode: 'self',
    modeBadge: '',
    inputText: '',
    status: '',
    sending: false,
    listening: false,
    generating: false,
    settingsOpen: false,
    voiceInputOn: true,
    dialects: ['普通话', '粤语（广东话）', '台湾国语'],
    dialectIndex: 0,
    memoirOpen: false,
    memoirTitle: '',
    memoirBlocks: [],
    memoirRaw: '',
    editing: false,
    confirmed: false,
    scrollInto: ''
  },

  conversation: [],
  photos: [],
  asrManager: null,
  asrBaseText: '',
  asrFinalText: '',
  asrStopToSend: false,

  onLoad(options) {
    const mode = options && options.mode === 'child' ? 'child' : 'self';
    this.initConversation(mode);
    this.initAsr();
  },

  initConversation(mode) {
    this.conversation = [
      { role: 'system', content: mode === 'child' ? SYSTEM_PROMPT_CHILD : SYSTEM_PROMPT_SELF },
      { role: 'assistant', content: mode === 'child' ? GREETING_CHILD : GREETING_SELF }
    ];
    this.photos = [];
    this.setData({
      mode,
      modeBadge: mode === 'child' ? '子女代发起' : '本人自述',
      messages: [{ role: 'ai', content: mode === 'child' ? GREETING_CHILD : GREETING_SELF }],
      status: mode === 'child'
        ? '💡 您的孩子托我来听您讲故事——想聊就聊，不想聊也没关系'
        : '💡 点 🎤 说话，或打字；点 📷 可以给我看老照片'
    });
    this.scrollBottom();
  },

  scrollBottom() {
    this.setData({ scrollInto: 'msg-bottom' });
  },

  // ===== 云函数调用（DeepSeek 代理，Key 在云端） =====
  callCloud(messages, maxTokens, temperature) {
    return wx.cloud.callFunction({
      name: 'chatProxy',
      data: { messages, max_tokens: maxTokens, temperature }
    }).then(res => {
      const r = res.result;
      if (r && r.error) throw new Error(r.error);
      if (!r || !r.choices) throw new Error('服务返回异常');
      return r;
    });
  },

  // 空正文自动重试保护（v4-pro 推理模型特性）
  async callDeepSeek(messages, maxTokens, temperature) {
    let attemptTokens = maxTokens;
    let attemptMessages = messages;
    for (let attempt = 0; attempt < 2; attempt++) {
      const data = await this.callCloud(attemptMessages, attemptTokens, temperature);
      const choice = data.choices && data.choices[0];
      const content = (choice && choice.message && choice.message.content) || '';
      const finishReason = choice ? choice.finish_reason : '';
      if (content.trim() || finishReason !== 'length' || attempt === 1) {
        return data;
      }
      attemptTokens = Math.min(attemptTokens * 2, 8192);
      attemptMessages = attemptMessages.concat([{ role: 'user', content: '请直接给出回答正文。' }]);
    }
  },

  // ===== 发送消息 =====
  onInput(e) {
    this.setData({ inputText: e.detail.value });
  },

  async sendMessage() {
    const text = (this.data.inputText || '').trim();
    if (!text || this.data.sending) return;
    this.conversation.push({ role: 'user', content: text });
    const messages = this.data.messages.concat([{ role: 'user', content: text }]);
    this.setData({ messages, inputText: '', sending: true, status: '🤔 正在思考…' });
    this.scrollBottom();
    try {
      const data = await this.callDeepSeek(this.conversation, 1024, 0.8);
      const reply = data.choices[0].message.content;
      this.conversation.push({ role: 'assistant', content: reply });
      this.setData({
        messages: this.data.messages.concat([{ role: 'ai', content: reply }]),
        status: '💬 继续讲，我在听…'
      });
      this.scrollBottom();
    } catch (err) {
      this.conversation.pop();
      this.setData({ status: '❌ ' + (err.message || '发送失败，请重试') });
    } finally {
      this.setData({ sending: false });
    }
  },

  // ===== 老照片（记忆锚点） =====
  choosePhoto() {
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sourceType: ['album', 'camera'],
      success: async (res) => {
        const file = res.tempFiles[0].tempFilePath;
        const compressed = await this.compressImage(file);
        const base64 = await this.readBase64(compressed);
        if (!base64) {
          wx.showToast({ title: '照片读取失败', icon: 'none' });
          return;
        }
        this.photos.push({ dataUrl: 'data:image/jpeg;base64,' + base64, path: compressed });
        const idx = this.photos.length;
        this.setData({
          messages: this.data.messages.concat([{ role: 'user', content: '', photo: compressed }]),
          status: '📷 照片收到了，我看看…'
        });
        this.scrollBottom();
        await this.sendImageMessage(idx);
      }
    });
  },

  compressImage(src) {
    return new Promise((resolve) => {
      wx.compressImage({
        src,
        quality: 60,
        success: (r) => resolve(r.tempFilePath),
        fail: () => resolve(src)
      });
    });
  },

  readBase64(filePath) {
    return new Promise((resolve) => {
      wx.getFileSystemManager().readFile({
        filePath,
        encoding: 'base64',
        success: (r) => resolve(r.data),
        fail: () => resolve(null)
      });
    });
  },

  async sendImageMessage(idx) {
    if (this.data.sending) return;
    this.setData({ sending: true, status: '🤔 正在思考…' });
    const photo = this.photos[idx - 1];
    const visionMsg = {
      role: 'user',
      content: [
        { type: 'text', text: '我给您看一张老照片。（这是第' + idx + '张照片）' },
        { type: 'image_url', image_url: { url: photo.dataUrl } }
      ]
    };
    try {
      const data = await this.callDeepSeek(this.conversation.concat([visionMsg]), 1024, 0.8);
      const reply = data.choices[0].message.content;
      this.conversation.push(visionMsg);
      this.conversation.push({ role: 'assistant', content: reply });
      this.setData({
        messages: this.data.messages.concat([{ role: 'ai', content: reply }]),
        status: '💬 继续讲，我在听…'
      });
      this.scrollBottom();
    } catch (err) {
      // 视觉接口异常时回退：文字告知 AI，照片仍保留
      try {
        const data = await this.callDeepSeek(
          this.conversation.concat([{ role: 'user', content: '（老人上传了一张老照片，请引导他讲讲照片里的人与事）' }]),
          1024, 0.8);
        const reply = data.choices[0].message.content;
        this.conversation.push({ role: 'user', content: '' });
        this.conversation.push({ role: 'assistant', content: reply });
        this.setData({
          messages: this.data.messages.concat([{ role: 'ai', content: reply }]),
          status: '💬 继续讲，我在听…'
        });
        this.scrollBottom();
      } catch (e2) {
        this.setData({ status: '❌ ' + (e2.message || '发送失败') });
      }
    } finally {
      this.setData({ sending: false });
    }
  },

  // ===== 语音输入（微信同声传译插件） =====
  initAsr() {
    if (!asrPlugin) return;
    try {
      this.asrManager = asrPlugin.getRecordRecognitionManager();
      this.asrManager.onRecognize = (res) => {
        this.setData({
          inputText: this.asrBaseText + (this.asrBaseText ? ' ' : '') + this.asrFinalText + (res.result || '')
        });
      };
      this.asrManager.onStop = (res) => {
        if (res.result) this.asrFinalText += res.result;
        this.setData({
          inputText: this.asrBaseText + (this.asrBaseText ? ' ' : '') + this.asrFinalText,
          listening: false
        });
        if (this.asrStopToSend) {
          this.asrStopToSend = false;
          this.finishListening();
        }
      };
      this.asrManager.onError = () => {
        this.setData({ listening: false, status: '⚠️ 语音识别出错，请重试' });
      };
    } catch (e) {
      this.asrManager = null;
    }
  },

  toggleMic() {
    if (!this.data.voiceInputOn) {
      wx.showToast({ title: '请先在设置里开启语音输入', icon: 'none' });
      return;
    }
    if (this.data.listening) {
      this.stopListeningAndSend();
    } else {
      this.startListening();
    }
  },

  startListening() {
    if (this.data.listening) return;
    if (!this.asrManager) {
      wx.showToast({ title: '语音插件未添加（见 README）', icon: 'none' });
      return;
    }
    this.asrBaseText = (this.data.inputText || '').trim();
    this.asrFinalText = '';
    this.asrStopToSend = false;
    this.setData({ listening: true, status: '🎤 正在听您说话… 说完了请再点一下红色按钮' });
    try {
      // 插件 0.3.10：普通话 zh_CN、粤语 zh_HK；台湾国语按普通话识别
      const langMap = ['zh_CN', 'zh_HK', 'zh_CN'];
      this.asrManager.start({ lang: langMap[this.data.dialectIndex] || 'zh_CN', duration: 60000 });
    } catch (e) {
      this.setData({ listening: false, status: '⚠️ 语音启动失败' });
    }
  },

  stopListeningAndSend() {
    this.asrStopToSend = true;
    try {
      this.asrManager.stop();
    } catch (e) {
      this.asrStopToSend = false;
      this.setData({ listening: false });
      this.finishListening();
    }
  },

  finishListening() {
    if ((this.data.inputText || '').trim()) {
      this.sendMessage();
    } else {
      this.setData({ status: '💡 没有听到内容，请再点一下 🎤 试试' });
    }
  },

  // ===== 生成回忆录（零添加、第一人称） =====
  async generateMemoir() {
    if (this.data.generating) return;
    const msgs = this.conversation.filter(m => m.role !== 'system');
    if (msgs.length <= 1) {
      this.setData({ status: '💡 再多聊一会儿吧，回忆录需要更多故事素材' });
      return;
    }
    this.setData({ generating: true, status: '📝 正在整理您的回忆录，请稍候…' });
    wx.showLoading({ title: '正在整理回忆录…', mask: true });

    const memoirMessages = [
      { role: 'system', content: MEMOIR_SYSTEM_PROMPT },
      ...this.serializeForMemoir(),
      { role: 'user', content: '请根据以上全部访谈素材，撰写我的回忆录。' }
    ];
    try {
      let memoirText = '';
      for (let round = 0; round < 8; round++) {
        const data = await this.callDeepSeek(memoirMessages, 2048, 0.7);
        const choice = data.choices[0];
        const chunk = (choice.message.content || '').trim();
        memoirText += chunk;
        memoirMessages.push({ role: 'assistant', content: choice.message.content });
        if (choice.finish_reason !== 'length') break;
        memoirMessages.push({
          role: 'user',
          content: '上文被截断了。请接着刚才断掉的地方继续往下写，把正文完整写完；不要重复已经写过的内容。'
        });
      }
      memoirText = memoirText.trim();
      const parsed = this.buildMemoirBlocks(memoirText);
      this.setData({
        memoirTitle: parsed.title,
        memoirBlocks: parsed.blocks,
        memoirRaw: memoirText,
        memoirOpen: true,
        editing: false,
        confirmed: false,
        status: '📖 回忆录已生成！请改一改、确认后交给家人'
      });
    } catch (err) {
      this.setData({ status: '❌ ' + (err.message || '生成失败') });
    } finally {
      wx.hideLoading();
      this.setData({ generating: false });
    }
  },

  serializeForMemoir() {
    return this.conversation.filter(m => m.role !== 'system').map(m => {
      if (m.role === 'user') {
        const imgNote = '';
        return { role: 'user', content: imgNote + (typeof m.content === 'string' ? m.content : '（上传了照片）') };
      }
      return { role: 'assistant', content: m.content };
    });
  },

  buildMemoirBlocks(text) {
    const lines = text.split(/\n+/).map(s => s.trim()).filter(Boolean);
    const blocks = [];
    let title = '';
    let inToc = false;
    lines.forEach(line => {
      if (/^【开篇】/.test(line)) {
        blocks.push({ type: 'kai', text: line.replace(/^【开篇】\s*：?\s*/, '') });
      } else if (/^【目录】/.test(line)) {
        inToc = true;
      } else if (/^【正文】/.test(line)) {
        inToc = false;
      } else if (/^第[一二三四五六七八九十百0-9０-９]+章/.test(line)) {
        blocks.push({ type: 'chap', text: line });
      } else if (inToc) {
        blocks.push({ type: 'toc', text: line });
      } else if (!title && !/^【/.test(line)) {
        title = line;
      } else {
        const parts = line.split(/【照片(\d+)】/);
        const segs = [];
        parts.forEach((p, i) => {
          if (i % 2 === 1) {
            const idx = parseInt(p, 10) - 1;
            const ph = this.photos[idx];
            if (ph) segs.push({ type: 'photo', photo: ph.path });
            else segs.push({ type: 'text', text: '【照片' + p + '】' });
          } else if (p.trim()) {
            segs.push({ type: 'text', text: p });
          }
        });
        if (segs.length) blocks.push({ type: 'para', segs });
      }
    });
    return { title, blocks };
  },

  // ===== 回忆录面板操作 =====
  closeMemoir() {
    this.setData({ memoirOpen: false });
  },

  toggleEdit() {
    this.setData({ editing: !this.data.editing });
  },

  onMemoirInput(e) {
    this.setData({ memoirRaw: e.detail.value });
  },

  confirmMemoir() {
    this.setData({
      confirmed: true,
      status: '✅ 已定稿——这是您点头认可的书，请交给家人保存，留给孙子孙女'
    });
  },

  downloadMemoir() {
    const text = (this.data.memoirRaw || '').replace(/【照片(\d+)】/g, '【此处附老照片 $1】');
    if (!text.trim()) return;
    const paged = this.paginateMemoir(text);
    const filePath = wx.env.USER_DATA_PATH + '/我的回忆录.txt';
    wx.getFileSystemManager().writeFile({
      filePath,
      data: paged,
      encoding: 'utf8',
      success: () => {
        wx.openDocument({
          filePath,
          fileType: 'txt',
          showMenu: true,
          fail: () => {
            wx.setClipboardData({ data: paged });
          }
        });
        this.setData({ status: '💾 已生成文件（纯文本格式，长期可读），请保存或转发给家人' });
      },
      fail: () => {
        wx.setClipboardData({ data: paged, success: () => {
          this.setData({ status: '💾 已复制全文，请粘贴保存' });
        }});
      }
    });
  },

  paginateMemoir(text, charsPerPage = 500) {
    const blocks = text.split(/\n+/).map(b => b.trim()).filter(Boolean);
    const pages = [];
    let page = [];
    let len = 0;
    let inToc = false;
    const flush = () => { if (page.length) { pages.push(page); page = []; len = 0; } };
    blocks.forEach(block => {
      const isSection = /^【.+】/.test(block);
      if (isSection) {
        if (!block.includes('正文')) flush();
        inToc = block.includes('目录');
      }
      const isChapter = !inToc && /^第[一二三四五六七八九十百0-9０-９]+章/.test(block);
      if (isChapter) {
        const lastIsMarker = page.length > 0 && /^【|^第/.test(page[page.length - 1]);
        if (!lastIsMarker) flush();
      }
      page.push(block);
      len += block.length;
      if (len >= charsPerPage) flush();
    });
    flush();
    return pages.map((p, i) => p.join('\n\n') + '\n\n— 第 ' + (i + 1) + ' 页 —').join('\n\n\n');
  },

  // ===== 设置面板 =====
  openSettings() {
    this.setData({ settingsOpen: true });
  },
  closeSettings() {
    this.setData({ settingsOpen: false });
  },
  onVoiceInputToggle(e) {
    this.setData({ voiceInputOn: e.detail.value });
  },
  onDialectChange(e) {
    this.setData({ dialectIndex: Number(e.detail.value) });
  },

  goBack() {
    wx.navigateBack();
  }
});
