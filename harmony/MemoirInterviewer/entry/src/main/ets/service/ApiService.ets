import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './Config';
import { SettingsService } from './SettingsService';

const DOMAIN: number = 0x0000;

export interface ChatMessage {
  role: string;
  content: string;
}

/**
 * 调用 DeepSeek Chat Completions，返回 OpenAI 格式的原始 JSON 字符串，
 * 由网页端 JSON.parse 后按既有逻辑解析（choices[0].message.content 等）。
 * API Key 从本机设置读取，网页端无法接触到。
 */
export async function callChatApi(messages: ChatMessage[], maxTokens: number, temperature: number): Promise<string> {
  const apiKey = await SettingsService.getApiKey();
  if (!apiKey || apiKey === AppConfig.DEFAULT_API_KEY || apiKey === '') {
    throw new Error('请先在"设置"页填写 DeepSeek API Key');
  }

  const request = http.createHttp();
  try {
    const response = await request.request(AppConfig.API_URL, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey
      },
      extraData: JSON.stringify({
        model: AppConfig.MODEL,
        messages: messages,
        stream: false,
        max_tokens: maxTokens,
        temperature: temperature
      }),
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 120000,   // 弱网/慢网环境给足时间（农村 2G/3G 也能用）
      readTimeout: 360000
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
