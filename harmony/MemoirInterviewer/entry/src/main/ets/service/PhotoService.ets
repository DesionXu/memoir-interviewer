import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const MAX_EDGE: number = 1280;

/**
 * 老照片选图（PRD-02 步6：照片是记忆锚点，子女可代传）：
 * 系统相册选择器（无需存储权限）→ 解码 → 等比缩到最长边 1280 →
 * JPEG(75%) → base64 data URL 回传网页，随消息发送给多模态模型读图。
 */
export class PhotoService {
  static async pickAndRead(): Promise<string> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    const uris: string[] = result.photoUris;
    if (!uris || uris.length === 0) {
      throw new Error('未选择照片');
    }
    const uri: string = uris[0];

    let file: fs.File | null = null;
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      if (stat.size <= 0) {
        throw new Error('照片读取失败');
      }

      // 解码并缩放（老照片来自手机相机，通常数 MB，缩放后发送体积可控）
      const imageSource: image.ImageSource = image.createImageSource(file.fd);
      const pixelMap: image.PixelMap = await imageSource.createPixelMap({
        desiredSize: { width: MAX_EDGE, height: MAX_EDGE }
      });
      const packer: image.ImagePacker = image.createImagePacker();
      const packed: ArrayBuffer = await packer.packing(pixelMap, {
        format: 'image/jpeg',
        quality: 75
      });

      const base64: string = new util.Base64Helper().encodeToStringSync(new Uint8Array(packed));
      packer.release();
      pixelMap.release();
      imageSource.release();
      return 'data:image/jpeg;base64,' + base64;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'PhotoService', 'pickAndRead failed: %{public}s', e.message);
      throw new Error('照片处理失败：' + e.message);
    } finally {
      if (file) {
        fs.closeSync(file);
      }
    }
  }
}
