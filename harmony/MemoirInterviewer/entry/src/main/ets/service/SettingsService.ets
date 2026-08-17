import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const STORE_NAME: string = 'memoir_settings';
const KEY_API_KEY: string = 'api_key';

/**
 * 本机设置存储（preferences）：保存 DeepSeek API Key，仅存本机，不上传。
 */
export class SettingsService {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    if (SettingsService.store) {
      return;
    }
    try {
      SettingsService.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'SettingsService', 'init failed: %{public}s', e.message);
    }
  }

  static async getApiKey(): Promise<string> {
    if (!SettingsService.store) {
      return '';
    }
    try {
      const value = await SettingsService.store.get(KEY_API_KEY, '');
      return value as string;
    } catch (err) {
      return '';
    }
  }

  static async setApiKey(key: string): Promise<void> {
    if (!SettingsService.store) {
      return;
    }
    try {
      await SettingsService.store.put(KEY_API_KEY, key);
      await SettingsService.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'SettingsService', 'setApiKey failed: %{public}s', e.message);
    }
  }
}
