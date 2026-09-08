// ============================================
// 云函数：DeepSeek 代理
// API Key 保存在云函数环境变量 DEEPSEEK_API_KEY 中，
// 客户端永远接触不到 Key。
// 部署：微信开发者工具 → 云开发 → 上传并部署本目录，
//       然后在云开发控制台 → 云函数 → chatProxy → 配置 → 环境变量
//       添加 DEEPSEEK_API_KEY = sk-xxxx
// ============================================
const https = require('https');

const API_KEY = process.env.DEEPSEEK_API_KEY || '';
const API_URL = 'https://api.deepseek.com/v1/chat/completions';

exports.main = async (event) => {
  const messages = event.messages;
  const maxTokens = event.max_tokens || 1024;
  const temperature = event.temperature !== undefined ? event.temperature : 0.8;

  if (!API_KEY) {
    return { error: '云函数未配置 DEEPSEEK_API_KEY 环境变量' };
  }
  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return { error: '缺少 messages 参数' };
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
      timeout: 300000
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
      resolve({ error: '请求超时（生成回忆录较长时属正常，请重试）' });
    });
    req.on('error', (e) => {
      resolve({ error: e.message });
    });
    req.write(payload);
    req.end();
  });
};
