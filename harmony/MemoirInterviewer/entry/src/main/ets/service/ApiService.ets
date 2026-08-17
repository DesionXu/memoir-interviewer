import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './Config';

const DOMAIN: number = 0x0000;

export interface ChatMessage {
  role: string;
  content: string;
}

/**
 * 调用 DeepSeek Chat Completions，返回 OpenAI 格式的原始 JSON 字符串，
 * 由网页端 JSON.parse 后按既有逻辑解析（choices[0].message.content 等）。
 */
export async function callChatApi(messages: ChatMessage[], maxTokens: number, temperature: number): Promise<string> {
  const request = http.createHttp();
  try {
    const response = await request.request(AppConfig.API_URL, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + AppConfig.API_KEY
      },
      extraData: JSON.stringify({
        model: AppConfig.MODEL,
        messages: messages,
        stream: false,
        max_tokens: maxTokens,
        temperature: temperature
      }),
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 180000
    });
    if (response.responseCode !== 200) {
      hilog.error(DOMAIN, 'ApiService', 'DeepSeek API error: %{public}d', response.responseCode);
      throw new Error('API 返回错误码 ' + response.responseCode);
    }
    return response.result as string;
  } catch (err) {
    const e = err as BusinessError;
    hilog.error(DOMAIN, 'ApiService', 'request failed: %{public}s', e.message);
    throw new Error('请求失败：' + e.message);
  } finally {
    request.destroy();
  }
}
