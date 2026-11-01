// ============================================
// 云函数：DeepSeek 代理（支持老照片识别）
// API Key 保存在云函数环境变量 DEEPSEEK_API_KEY 中，客户端接触不到 Key。
//
// 照片处理：小程序端的 callFunction 参数有 100KB 级传输限制，
// 直接塞 base64 图片会让视觉请求失败。因此客户端先把照片上传云存储，
// 只把临时 HTTPS 链接传给云函数；云函数在这里下载图片、转成 base64
// data URL，再发给 DeepSeek 视觉接口。
//
// 部署：微信开发者工具 → 云开发 → 云函数 → 右键 chatProxy →
//       上传并部署（云端安装依赖）；环境变量里配置 DEEPSEEK_API_KEY。
// ============================================
const https = require('https');
const http = require('http');

const API_KEY = process.env.DEEPSEEK_API_KEY || '';
const API_URL = 'https://api.deepseek.com/v1/chat/completions';
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;   // 单张图片上限 8MB

// 下载远程图片，返回 data URL（供视觉接口使用）
function fetchImageAsDataUrl(url, redirectsLeft) {
  const left = redirectsLeft === undefined ? 3 : redirectsLeft;
  return new Promise((resolve, reject) => {
    const lib = url.indexOf('http://') === 0 ? http : https;
    const req = lib.get(url, { timeout: 20000 }, (res) => {
      // 跟随重定向（云存储/签名链接常见）
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && left > 0) {
        res.resume();
        resolve(fetchImageAsDataUrl(res.headers.location, left - 1));
        return;
      }
      if (res.statusCode !== 200) {
        res.resume();
        reject(new Error('图片下载失败（HTTP ' + res.statusCode + '）'));
        return;
      }
      const chunks = [];
      let size = 0;
      res.on('data', (chunk) => {
        size += chunk.length;
        if (size > MAX_IMAGE_BYTES) {
          req.destroy();
          reject(new Error('图片过大'));
          return;
        }
        chunks.push(chunk);
      });
      res.on('end', () => {
        const contentType = String(res.headers['content-type'] || 'image/jpeg').split(';')[0];
        const base64 = Buffer.concat(chunks).toString('base64');
        resolve('data:' + contentType + ';base64,' + base64);
      });
    });
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('图片下载超时'));
    });
  });
}

// 把 messages 里所有 http(s) 图片链接替换成 base64 data URL
async function inlineRemoteImages(messages) {
  for (const msg of messages) {
    if (!msg || !Array.isArray(msg.content)) continue;
    for (const part of msg.content) {
      if (!part || part.type !== 'image_url') continue;
      const url = part.image_url && part.image_url.url;
      if (typeof url === 'string' && /^https?:\/\//.test(url)) {
        const dataUrl = await fetchImageAsDataUrl(url);
        part.image_url.url = dataUrl;
      }
    }
  }
  return messages;
}

exports.main = async (event) => {
  const maxTokens = event.max_tokens || 1024;
  const temperature = event.temperature !== undefined ? event.temperature : 0.8;
  let messages = event.messages;

  if (!API_KEY) {
    return { error: '云函数未配置 DEEPSEEK_API_KEY 环境变量' };
  }
  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return { error: '缺少 messages 参数' };
  }

  // 老照片：先下载成 base64，再送模型
  let hasImage = false;
  try {
    for (const msg of messages) {
      if (msg && Array.isArray(msg.content) &&
          msg.content.some((p) => p && p.type === 'image_url')) {
        hasImage = true;
      }
    }
    if (hasImage) {
      messages = await inlineRemoteImages(messages);
    }
  } catch (err) {
    return { error: '照片读取失败：' + ((err && err.message) || '未知错误') };
  }

  const payload = JSON.stringify({
    model: 'deepseek-v4-pro',
    messages: messages,
    stream: false,
    max_tokens: maxTokens,
    temperature: temperature
  });

  return new Promise((resolve) => {
    const req = https.request(API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + API_KEY,
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: 55000
    }, (res) => {
      let body = '';
      res.on('data', (c) => { body += c; });
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.error) {
            resolve({ error: data.error.message || 'DeepSeek 返回错误' });
          } else {
            resolve(data);
          }
        } catch (e) {
          resolve({ error: '响应解析失败' });
        }
      });
    });
    req.on('timeout', () => {
      req.destroy();
      resolve({ error: '请求超时（内容较长，请重试一次）' });
    });
    req.on('error', (e) => {
      resolve({ error: e.message });
    });
    req.write(payload);
    req.end();
  });
};
