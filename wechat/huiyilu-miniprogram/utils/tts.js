// ============================================
// 语音播报（TTS）：微信同声传译插件 textToSpeech
// 老人眼睛花、看字费力，AI 的每一句回答都可以念出来。
// 插件合成返回音频文件（res.filename），用 InnerAudioContext 顺序播放。
// 长文本自动按句切分，逐段合成播放，避免单次合成字数超限。
// ============================================

const MAX_CHUNK = 100;   // 单段最大字数（插件单次合成限制留余量）

/**
 * 把长文本按标点切成若干段，每段不超过 MAX_CHUNK 字。
 * 尽量在句号、问号、分号、换行处断开，避免念到一半断句。
 */
function splitText(text) {
  const raw = String(text || '').replace(/\s+/g, ' ').trim();
  if (!raw) return [];
  const pieces = raw.match(/[^。！？；!?;\n]+[。！？；!?;\n]?/g) || [raw];
  const chunks = [];
  let cur = '';
  pieces.forEach((p) => {
    const piece = p.trim();
    if (!piece) return;
    if ((cur + piece).length > MAX_CHUNK && cur) {
      chunks.push(cur);
      cur = piece;
    } else {
      cur += piece;
    }
    // 单句本身就超长：硬切
    while (cur.length > MAX_CHUNK) {
      chunks.push(cur.slice(0, MAX_CHUNK));
      cur = cur.slice(MAX_CHUNK);
    }
  });
  if (cur) chunks.push(cur);
  return chunks;
}

class TtsPlayer {
  constructor(options) {
    const opt = options || {};
    this.lang = 'zh_CN';
    this.queue = [];
    this.playing = false;
    this.audio = null;
    this.onError = opt.onError || function () {};
    this.onSpeakingChange = opt.onSpeakingChange || function () {};
  }

  // 插件可能未添加（未在 mp 后台授权），做容错
  static getPlugin() {
    try {
      return requirePlugin('WechatSI');
    } catch (e) {
      return null;
    }
  }

  init() {
    if (this.audio) return;
    this.audio = wx.createInnerAudioContext();
    this.audio.obeyMuteSwitch = false;   // 静音键也能播报（老人常忘开声音）
    this.audio.onEnded(() => {
      this.next();
    });
    this.audio.onError(() => {
      // 单段播放失败不阻塞后续
      this.next();
    });
  }

  /**
   * 播报一段文字（会打断当前正在播报的内容）
   * @param {string} text
   * @param {string} lang zh_CN / zh_HK
   */
  speak(text, lang) {
    if (!text) return;
    this.init();
    this.stop();
    this.lang = lang === 'zh_HK' ? 'zh_HK' : 'zh_CN';
    this.queue = splitText(text);
    if (!this.queue.length) return;
    this.speakNext();
  }

  speakNext() {
    if (!this.queue.length) {
      this.setPlaying(false);
      return;
    }
    const plugin = TtsPlayer.getPlugin();
    if (!plugin || typeof plugin.textToSpeech !== 'function') {
      this.queue = [];
      this.setPlaying(false);
      this.onError('语音播报暂不可用（同声传译插件未授权）');
      return;
    }
    const content = this.queue.shift();
    this.setPlaying(true);
    plugin.textToSpeech({
      lang: this.lang,
      tts: true,
      content: content,
      success: (res) => {
        if (!res || !res.filename) {
          this.next();
          return;
        }
        this.audio.src = res.filename;
        this.audio.play();
      },
      fail: () => {
        // 粤语合成失败时回退普通话，再试一次同一段
        if (this.lang === 'zh_HK') {
          this.lang = 'zh_CN';
          this.queue.unshift(content);
          this.speakNext();
        } else {
          this.onError('语音播报失败，请稍后再试');
          this.next();
        }
      }
    });
  }

  next() {
    this.speakNext();
  }

  setPlaying(v) {
    if (this.playing !== v) {
      this.playing = v;
      this.onSpeakingChange(v);
    }
  }

  stop() {
    this.queue = [];
    this.setPlaying(false);
    if (this.audio) {
      try {
        this.audio.stop();
      } catch (e) {}
    }
  }

  destroy() {
    this.stop();
    if (this.audio) {
      try {
        this.audio.destroy();
      } catch (e) {}
      this.audio = null;
    }
  }
}

module.exports = { TtsPlayer, splitText };
