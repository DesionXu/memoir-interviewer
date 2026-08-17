import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 运行时申请麦克风权限（module.json5 已声明 reason 文案）。
 * @returns true 表示已授权
 */
export async function ensureMicPermission(context: common.Context): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  try {
    const result = await atManager.requestPermissionsFromUser(context, [Permissions.MICROPHONE]);
    return result.authResults.length > 0 && result.authResults[0] === 0;
  } catch (err) {
    const e = err as BusinessError;
    return false;
  }
}
