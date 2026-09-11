import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const STORE_NAME: string = 'hy_analytics';
const KEY_EVENTS: string = 'events';
const MAX_EVENTS: number = 2000;

/**
 * 试用期轻量埋点（PRD-03：不建设数据平台，用轻量埋点 + 每周人工随访）。
 * 事件格式："ISO时间|事件名|附加信息"，仅存本机 preferences，
 * 在设置页「试用数据」中查看与复制导出，供试用期人工统计 L1-L6 漏斗。
 */
export class AnalyticsService {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    if (AnalyticsService.store) {
      return;
    }
    try {
      AnalyticsService.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AnalyticsService', 'init failed: %{public}s', e.message);
    }
  }

  static async track(event: string, payload: string = ''): Promise<void> {
    if (!AnalyticsService.store) {
      return;
    }
    try {
      const raw = await AnalyticsService.store.get(KEY_EVENTS, '[]') as string;
      let list: string[] = [];
      try {
        list = JSON.parse(raw) as string[];
      } catch (err) {
        list = [];
      }
      const line = new Date().toISOString() + '|' + event + (payload ? '|' + payload : '');
      list.push(line);
      if (list.length > MAX_EVENTS) {
        list = list.slice(-MAX_EVENTS);
      }
      await AnalyticsService.store.put(KEY_EVENTS, JSON.stringify(list));
      await AnalyticsService.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AnalyticsService', 'track failed: %{public}s', e.message);
    }
  }

  static async getAll(): Promise<string[]> {
    if (!AnalyticsService.store) {
      return [];
    }
    try {
      const raw = await AnalyticsService.store.get(KEY_EVENTS, '[]') as string;
      return JSON.parse(raw) as string[];
    } catch (err) {
      return [];
    }
  }

  static async clear(): Promise<void> {
    if (!AnalyticsService.store) {
      return;
    }
    try {
      await AnalyticsService.store.put(KEY_EVENTS, '[]');
      await AnalyticsService.store.flush();
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AnalyticsService', 'clear failed: %{public}s', e.message);
    }
  }
}
