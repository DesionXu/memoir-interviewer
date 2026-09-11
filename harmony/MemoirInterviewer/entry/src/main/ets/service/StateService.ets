import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const STORE_NAME: string = 'hy_state';
const KEY_CONVERSATION: string = 'conversation';

/**
 * 访谈状态持久化（PRD-02：可中断可续接；下次开场先复述进度）。
 * 保存访谈对话（仅文字，照片不落盘）到本机 preferences，
 * 由网页通过 HarmonyBridge.saveState / loadState 读写。
 */
export class StateService {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    if (StateService.store) {
      return;
    }
    try {
      StateService.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'StateService', 'init failed: %{public}s', e.message);
    }
  }

  static async save(json: string): Promise<void> {
    if (!StateService.store) {
      return;
    }
    try {
      await StateService.store.put(KEY_CONVERSATION, json);
      await StateService.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'StateService', 'save failed: %{public}s', e.message);
    }
  }

  static async load(): Promise<string> {
    if (!StateService.store) {
      return '';
    }
    try {
      const value = await StateService.store.get(KEY_CONVERSATION, '');
      return value as string;
    } catch (err) {
      return '';
    }
  }

  static async clear(): Promise<void> {
    if (!StateService.store) {
      return;
    }
    try {
      await StateService.store.put(KEY_CONVERSATION, '');
      await StateService.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'StateService', 'clear failed: %{public}s', e.message);
    }
  }
}
