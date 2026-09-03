// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import PrintingPlugin from './PrintingPlugin';
import { pdfService } from '@kit.PDFKit';
import fs from '@ohos.file.fs';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { print } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

const TAG = 'Printing';

// 预定义纸张尺寸（mils 即 1/1000 英寸，纵向），与 print.PrintPageType 枚举值一一对应，
// 尺寸取值与 Android PrintAttributes.MediaSize 一致
interface PageSizeOption {
  type: print.PrintPageType;
  widthMils: number;
  heightMils: number;
}

const PREDEFINED_PAGE_SIZES: PageSizeOption[] = [
  { type: print.PrintPageType.PAGE_ISO_A3, widthMils: 11693, heightMils: 16535 },
  { type: print.PrintPageType.PAGE_ISO_A4, widthMils: 8268, heightMils: 11693 },
  { type: print.PrintPageType.PAGE_ISO_A5, widthMils: 5827, heightMils: 8268 },
  { type: print.PrintPageType.PAGE_JIS_B5, widthMils: 7165, heightMils: 10118 },
  { type: print.PrintPageType.PAGE_ISO_C5, widthMils: 6378, heightMils: 9016 },
  { type: print.PrintPageType.PAGE_ISO_DL, widthMils: 4331, heightMils: 8661 },
  { type: print.PrintPageType.PAGE_LETTER, widthMils: 8500, heightMils: 11000 },
  { type: print.PrintPageType.PAGE_LEGAL, widthMils: 8500, heightMils: 14000 },
  { type: print.PrintPageType.PAGE_PHOTO_4X6, widthMils: 4000, heightMils: 6000 },
  { type: print.PrintPageType.PAGE_PHOTO_5X7, widthMils: 5000, heightMils: 7000 },
  // PAGE_INT_DL_ENVELOPE 与 PAGE_ISO_DL 尺寸相同，不重复登记
  { type: print.PrintPageType.PAGE_B_TABLOID, widthMils: 11000, heightMils: 17000 }
];

export default class PrintingJob {
  private printing: PrintingPlugin;
  public index: number;
  private printingJobId: string | null = null;
  // 持有 setDocument 创建的 printAdapter 引用：任务结束/取消时置 null，
  // 打破 printAdapter → _this(本类) → printing(PrintingPlugin) → printJobs → 本类 的循环引用链，
  // 便于 GC 回收（系统打印服务可能仍短暂持有 adapter，但本类不再持有反向引用后链路即断开）
  private printAdapter: print.PrintDocumentAdapter | null = null;
  // 布局页宽高（PDF 点，来自 Dart 侧 PdfPageFormat），setDocument 时用于推导系统打印纸张尺寸
  private layoutWidth: number = 0;
  private layoutHeight: number = 0;

  constructor(printing: PrintingPlugin, index: number) {
    this.printing = printing;
    this.index = index;
  }

  static printingInfo(): Map<string, boolean> {
    let data: Map<string, boolean> = new Map();
    data.set('directPrint', false);
    // OHOS 的 onLayout 仅在 printPdf 入口触发一次，用户在打印面板中更改纸张/设置时
    // PrintDocumentAdapter 不会触发新的 onLayout 请求 Dart 重新生成 PDF（Android 由系统
    // onLayout 回调多次触发），不支持动态布局，如实返回 false
    data.set('dynamicLayout', false);
    data.set('canPrint', true);
    data.set('canShare', true);
    data.set('canRaster', true);
    // 显式声明能力边界，与 README 2.2 平台能力限制表一致（Dart 侧 PrintingInfo.fromMap
    // 虽有 ?? false 兜底，显式设置使能力声明完整、便于排查）：OHOS 无 HTML→PDF 转换
    // 与打印机枚举 API
    data.set('canConvertHtml', false);
    data.set('canListPrinters', false);
    return data
  }

  public printPdf(name: string, printJob: PrintingJob, width: number, height: number, marginLeft: number,
    marginTop: number, marginRight: number, marginBottom: number) {
    // 记录布局页尺寸，供 setDocument 推导 PrintAttributes 的纸张大小
    this.layoutWidth = width;
    this.layoutHeight = height;
    this.printing.onLayout(printJob, width, height, marginLeft, marginTop, marginRight, marginBottom);
  }

  rasterPdf(data: Uint8Array, pages: number[], scale: number): void {
    // 空值防护：data 为空无法光栅化，必须通知 Flutter 侧结束流，否则会无限等待
    if (data == null || data.length === 0) {
      Log.e(TAG, 'rasterPdf: empty pdf data');
      this.printing.onPageRasterEnd(this, 'Empty pdf data');
      return;
    }
    // 参数校验：scale 必须为正数，0 或负数会导致 pixelMap.scale() 行为异常（零缩放产生空图、负数镜像），
    // 非数字（如未传时为 undefined）同样无效。校验失败通知 Flutter 侧流结束
    if (typeof scale !== 'number' || scale <= 0) {
      Log.e(TAG, 'rasterPdf: invalid scale parameter: ' + scale);
      this.printing.onPageRasterEnd(this, 'Invalid scale parameter');
      return;
    }

    let context = getContext(this);
    let applicationContext = context.getApplicationContext();
    let tempDir = applicationContext.tempDir;
    let filePath = tempDir + '/raster.pdf';

    let pdfDocument: pdfService.PdfDocument | null = null;
    try {
      // 文件存在则删除
      let res = fs.accessSync(filePath);
      if (res) {
        fs.unlinkSync(filePath);
      }

      // 文件描述符泄漏修复：openSync/writeSync/closeSync 必须置于 try-finally，
      // writeSync 抛异常时 closeSync 仍执行，避免文件描述符泄漏
      let file: fs.File | null = null;
      try {
        file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.writeSync(file.fd, data.buffer);
      } finally {
        if (file != null) {
          try {
            fs.closeSync(file);
          } catch (e) {
            Log.e(TAG, 'rasterPdf close file error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
          }
        }
      }

      pdfDocument = new pdfService.PdfDocument();
      let loadResult = pdfDocument.loadDocument(filePath, '');
      if (loadResult != pdfService.ParseResult.PARSE_SUCCESS) {
        // 异常传播断裂点修复：加载失败必须调用 onPageRasterEnd，否则 Flutter 侧 StreamController 永不关闭
        Log.e(TAG, 'Failed to load pdf');
        this.printing.onPageRasterEnd(this, 'Failed to load pdf');
        return;
      }

      // pages 为空表示光栅化全部页；pages 非空时遍历指定页码（pages[i] 才是实际页索引）
      let pageCount = pages != null ? pages.length : pdfDocument.getPageCount();
      let totalPages = pdfDocument.getPageCount();
      for (let i = 0; i < pageCount; i++) {
        // pages 非空时取指定页码，否则按顺序遍历全部页
        let pageIndex = pages != null ? pages[i] : i;
        // 越界页码跳过，避免 getPage 抛出异常中断整个光栅化流
        if (pageIndex < 0 || pageIndex >= totalPages) {
          Log.e(TAG, 'rasterPdf: invalid page index: ' + pageIndex);
          continue;
        }
        let page = pdfDocument.getPage(pageIndex);
        // 基础渲染尺寸 = PDF 页面尺寸（PDF 点，72dpi 基准），与 Android PdfRenderer /
        // iOS CGPDFDocument 的光栅化基准一致；仅用于构造 PdfMatrix，
        // pixelMap.scale() 后实际像素为 baseWidth*scale × baseHeight*scale。
        // Dart 侧按 dpi/72 计算 scale，此处不可额外放大（曾用 *2 提升清晰度，
        // 导致相同 scale 下 OHOS 分辨率为 Android/iOS 的 2 倍、内存占用 ×4，行为不一致）
        let baseWidth = page.getWidth();
        let baseHeight = page.getHeight();
        let pdfMatrix: pdfService.PdfMatrix = new pdfService.PdfMatrix();
        pdfMatrix.x = 0;
        pdfMatrix.y = 0;
        pdfMatrix.rotate = 0;
        pdfMatrix.width = baseWidth;
        pdfMatrix.height = baseHeight
        // PixelMap 是原生图像资源，占用大量内存，必须用 try-finally 保证异常路径也释放
        let pixelMap: image.PixelMap | null = null;
        let newPixelMap: image.PixelMap | null = null;
        try {
          pixelMap = page.getCustomPagePixelMap(pdfMatrix, false, false);
          pixelMap.scale(scale, scale);
          // 原PixelMap颜色有问题，重新使用BGRA_8888输出PixelMap
          const imageInfo: image.ImageInfo = pixelMap.getImageInfoSync();
          const buffer: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
          pixelMap.readPixelsToBufferSync(buffer);
          const opts: image.InitializationOptions = {
            editable: false,
            pixelFormat: image.PixelMapFormat.RGBA_8888,
            size: {
              height: imageInfo.size.height, width: imageInfo.size.width
            }
          };
          newPixelMap = image.createPixelMapSync(buffer, opts);
          let pixelArrayBuffer: ArrayBuffer = new ArrayBuffer(newPixelMap.getPixelBytesNumber());
          newPixelMap.readPixelsToBufferSync(pixelArrayBuffer);
          let imageData: Uint8Array = new Uint8Array(pixelArrayBuffer);
          // 必须上报缩放后的实际维度（imageInfo 在 pixelMap.scale() 之后获取，size 即缩放结果，
          // 与 newPixelMap 的 size 一致）：Dart 侧 PdfRaster.toImage() 用 decodeImageFromPixels(pixels, width, height)
          // 解码，若上报未乘 scale 的基础维度会导致像素数与维度不匹配，图像畸变或解码异常
          this.printing.onPageRasterized(this, imageData, imageInfo.size.width, imageInfo.size.height);
        } finally {
          // 释放 PixelMap 原生内存：读取完成后立即释放，异常路径也必须释放，避免每页泄漏
          if (pixelMap != null) {
            this.releasePixelMap(pixelMap);
          }
          if (newPixelMap != null) {
            this.releasePixelMap(newPixelMap);
          }
        }
      }
      pdfDocument.releaseDocument();
      pdfDocument = null;
      this.printing.onPageRasterEnd(this, null);
    } catch (e) {
      let msg = e instanceof Error ? e.message : JSON.stringify(e);
      Log.e(TAG, 'rasterPdf error: ' + msg);
      // 异常传播断裂点修复：任何异常都必须通知 Flutter 侧流结束，避免无限等待
      this.printing.onPageRasterEnd(this, 'rasterPdf error: ' + msg);
    } finally {
      // 确保 PDF 文档资源释放，避免内存泄漏
      if (pdfDocument != null) {
        try {
          pdfDocument.releaseDocument();
        } catch (e) {
          Log.e(TAG, 'rasterPdf releaseDocument error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
        }
      }
      // 清理临时文件
      try {
        if (fs.accessSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (e) {
        Log.e(TAG, 'rasterPdf cleanup temp file error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
      }
    }
  }

  // 注意：body（随文档附加分享的文本）与 emails（邮件应用场景下的预设收件人地址列表）
  // 属于附加分享内容，OHOS 系统 Share API 仅支持共享 PDF 文件本身，不提供附加文本与
  // 收件人字段，故本方法不使用这两个参数；Dart 接口文档已标注二者仅 Android/iOS 生效
  static sharePdf(context: Context, data: Uint8Array, name: string, subject: string, body: string,
    emails: string[]): void {
    // 空值防护：无效输入直接抛出，由上层 onMethodCall 全局 catch 捕获并回传 Flutter 侧
    if (data == null || data.length === 0) {
      throw new Error('sharePdf: empty pdf data');
    }
    if (name == null) {
      throw new Error('sharePdf: name is null');
    }

    let applicationContext = context.getApplicationContext();
    let tempDir = applicationContext.tempDir;
    let filePath = tempDir + '/' + name + '.pdf';

    let controller: systemShare.ShareController;
    try {
      // 文件存在则删除
      let res = fs.accessSync(filePath);
      if (res) {
        fs.unlinkSync(filePath);
      }

      // 文件描述符泄漏修复：openSync/writeSync/closeSync 必须置于 try-finally，
      // writeSync 抛异常时 closeSync 仍执行，避免文件描述符泄漏
      let file: fs.File | null = null;
      try {
        file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.writeSync(file.fd, data.buffer);
      } finally {
        if (file != null) {
          try {
            fs.closeSync(file);
          } catch (e) {
            Log.e(TAG, 'sharePdf close file error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
          }
        }
      }

      let uri = fileUri.getUriFromPath(filePath);
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.PDF,
        title: name,
        description: subject,
        uri: uri
      });

      controller = new systemShare.ShareController(shareData);
      // 分享面板关闭（用户完成分享或取消）时清理临时文件：此时系统已读取完文件或用户放弃，
      // 是删除临时 PDF 的安全时机，避免 temp 目录文件持续累积。
      // on/off 对称 + 自清理：保存回调引用，dismiss 触发时先 off 取消自身订阅，
      // 防止回调在 controller 生命周期末端被重复触发或残留订阅，符合鸿蒙 on/off 最佳实践
      let dismissCallback: () => void = () => {
        try {
          controller.off('dismiss', dismissCallback);
        } catch (e) {
          Log.e(TAG, 'sharePdf off dismiss error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
        }
        PrintingJob.cleanupShareTempFile(filePath);
      };
      controller.on('dismiss', dismissCallback);
    } catch (e) {
      // 文件操作/URI 转换异常向上抛出，由 onMethodCall 全局 catch 传播到 Flutter 侧；
      // 此阶段抛出说明分享面板尚未展示，临时文件已无用，立即清理
      let msg = e instanceof Error ? e.message : JSON.stringify(e);
      Log.e(TAG, 'sharePdf error: ' + msg);
      PrintingJob.cleanupShareTempFile(filePath);
      throw new Error('sharePdf error: ' + msg);
    }

    // show() 返回 Promise：面板展示成功后 resolve，展示失败 reject。
    // 同步路径已正常返回 result.success(1)，此处仅观测异步结果用于日志与资源清理
    controller.show(context as common.UIAbilityContext, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      Log.d(TAG, 'sharePdf: share panel shown');
    }).catch((e: Object) => {
      // 面板展示失败（如参数非法、IPC 数据超限），清理临时文件并记录，便于排查
      Log.e(TAG, 'sharePdf show error: ' + JSON.stringify(e));
      PrintingJob.cleanupShareTempFile(filePath);
    });
  }

  cancelJob(message: string | null): void {
    if (this.printingJobId != null) {
      //cancelPrintJob是系统应用api
      //https://docs.openharmony.cn/pages/v4.1/zh-cn/application-dev/reference/apis-basic-services-kit/js-apis-print-sys.md#cancelprintjob-2
      //print.cancelPrintJob(this.printingJobId);

      this.printingJobId = null;
    }
    // 释放 printAdapter 闭包引用，打破循环引用链，便于 GC 回收本任务对象
    this.printAdapter = null;
    this.printing.onCompleted(this, false, message);
  }

  setDocument(data: Uint8Array): void {
    // 空值防护：无文档数据直接通知 Flutter 任务取消
    if (data == null || data.length === 0) {
      Log.e(TAG, 'setDocument: empty pdf data');
      this.printing.onCompleted(this, false, 'Empty pdf data');
      return;
    }

    let context = getContext(this);
    let applicationContext = context.getApplicationContext();
    let tempDir = applicationContext.tempDir;
    let filePath = tempDir + '/printing.pdf';

    let _this = this;
    let printAdapter: print.PrintDocumentAdapter = {
      onStartLayoutWrite(jobId: string,
        oldAttrs: print.PrintAttributes,
        newAttrs: print.PrintAttributes,
        fd: number,
        writeResultCallback: (jobId: string, writeResult: print.PrintFileCreationState) => void): void {
        _this.printingJobId = jobId;

        let mgr = getContext(_this).resourceManager;
        if (mgr === undefined) {
          Log.e(TAG, 'print mrg is undefined');
          // resourceManager 不可用时 early return 必须清理临时文件，否则 printing.pdf 会永久残留；
          // writeResultCallback 也未调用，系统打印服务可能不再触发 onJobStateChanged 终态清理
          _this.cleanupTempFile(filePath);
          _this.printing.onCompleted(_this, false, 'mrg is undefined');
          return;
        }
        let stream: fs.Stream | null = null;
        try {
          stream = fs.createStreamSync(filePath, 'r');
          const bufArray: ArrayBuffer[] = [];
          let totalLength = 0;
          let buf: ArrayBuffer = new ArrayBuffer(4096);
          let len: number = stream.readSync(buf);
          while (len !== 0) {
            totalLength += len;
            if (len < 4096) {
              buf = buf.slice(0, len);
              bufArray.push(buf);
              break;
            }
            bufArray.push(buf);
            buf = new ArrayBuffer(4096);
            len = stream.readSync(buf);
          }
          const contentBuf: Uint8Array = new Uint8Array(totalLength);
          let offset = 0;
          for (const bufArr of bufArray) {
            const uInt8Arr = new Uint8Array(bufArr);
            contentBuf.set(uInt8Arr, offset);
            offset += uInt8Arr.byteLength;
          }
          fs.writeSync(fd, contentBuf.buffer);
          writeResultCallback(jobId, print.PrintFileCreationState.PRINT_FILE_CREATED_UNRENDERED);
        } catch (e) {
          // 异常传播：文件读取/写入失败必须通知 Flutter 任务失败，否则任务会无限挂起
          let msg = e instanceof Error ? e.message : JSON.stringify(e);
          Log.e(TAG, 'setDocument onStartLayoutWrite error: ' + msg);
          _this.printing.onCompleted(_this, false, 'Write pdf error: ' + msg);
          // 尽早打破循环引用：布局写入失败意味着任务实质终止，立即释放 printAdapter 闭包引用，
          // 断开 printAdapter → _this → printing → printJobs → _this 的循环链，
          // 无需等待 onJobStateChanged 终态回调（置 null 幂等，后续终态回调再次置 null 无副作用）
          _this.printAdapter = null;
        } finally {
          // 必须关闭文件流，避免文件描述符泄漏
          if (stream != null) {
            try {
              stream.closeSync();
            } catch (e) {
              Log.e(TAG, 'setDocument close stream error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
            }
          }
        }
      },

      onJobStateChanged(jobId: string, state: print.PrintDocumentAdapterState): void {
        // 系统打印服务回调，可能在不同线程执行，必须 try-catch 保护：
        // 异常会导致应用崩溃，且临时文件在异常路径无法清理
        try {
          Log.d(TAG, 'print taskState: ' + JSON.stringify(state));
          _this.printingJobId = null;
          let success = state == print.PrintDocumentAdapterState.PRINT_TASK_SUCCEED;
          _this.printing.onCompleted(_this, success, null);
        } catch (e) {
          Log.e(TAG, 'onJobStateChanged error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
        } finally {
          // 打印任务结束后清理临时文件（正常/异常路径均执行）
          _this.cleanupTempFile(filePath);
          // 释放 printAdapter 闭包引用：本回调是任务终态，置 null 后 adapter 不再通过本类持有反向引用，
          // 打破 printAdapter → _this → printing → printJobs → _this 的循环引用链，便于 GC 回收
          _this.printAdapter = null;
        }
      }
    }
    // 持有 adapter 引用，便于任务结束时置 null 释放闭包（系统打印服务可能仍短暂持有，但循环链已断开）
    this.printAdapter = printAdapter;
    try {
      // 文件存在则删除
      let res = fs.accessSync(filePath);
      if (res) {
        fs.unlinkSync(filePath);
      }

      // 文件描述符泄漏修复：openSync/writeSync/closeSync 必须置于 try-finally，
      // writeSync 抛异常时 closeSync 仍执行，避免文件描述符泄漏
      let file: fs.File | null = null;
      try {
        file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
        fs.writeSync(file.fd, data.buffer);
      } finally {
        if (file != null) {
          try {
            fs.closeSync(file);
          } catch (e) {
            Log.e(TAG, 'setDocument close file error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
          }
        }
      }

      // 按文档布局尺寸推导打印属性（对齐 Android：根据 Dart 传入的页宽高匹配最接近的预定义纸张，
      // 匹配不到则按实际尺寸构造自定义纸张），pageRange 省略时系统默认打印全部页，颜色模式默认彩色
      let printAttributes: print.PrintAttributes = {
        copyNumber: 1,
        pageSize: this.matchPageSize(this.layoutWidth, this.layoutHeight),
        directionMode: print.PrintDirectionMode.DIRECTION_MODE_AUTO,
        colorMode: print.PrintColorMode.COLOR_MODE_COLOR,
        duplexMode: print.PrintDuplexMode.DUPLEX_MODE_NONE
      }
      print.print('printing_pdf', printAdapter, printAttributes, context);
    } catch (e) {
      // 异常传播：文件写入或打印 API 调用失败必须通知 Flutter 任务失败
      let msg = e instanceof Error ? e.message : JSON.stringify(e);
      Log.e(TAG, 'setDocument error: ' + msg);
      // 同步异常路径清理临时文件，避免 print.print() 抛出时文件残留
      this.cleanupTempFile(filePath);
      // 同步异常时任务未真正进入系统打印服务，释放 adapter 引用打破循环链
      this.printAdapter = null;
      this.printing.onCompleted(this, false, 'setDocument error: ' + msg);
    }
  }

  // 根据文档页面尺寸（PDF 点）匹配最接近的预定义纸张类型，对齐 Android PrintingJob.printPdf 的
  // 匹配逻辑：PDF 点 → mils（*1000/72），±20 mils 容差逐项比较；无匹配的预定义纸张时，
  // 按文档实际尺寸构造自定义 PrintPageSize（毫米），避免硬编码纸张导致非该尺寸文档打印预览缩放异常
  private matchPageSize(widthPt: number, heightPt: number): print.PrintPageSize | print.PrintPageType {
    // 布局尺寸缺失/非法时回退 A4（最常用纸张），避免 0 尺寸构造出非法的自定义纸张
    if (widthPt <= 0 || heightPt <= 0) {
      Log.w(TAG, 'matchPageSize: invalid layout size ' + widthPt + 'x' + heightPt + ', fallback to A4');
      return print.PrintPageType.PAGE_ISO_A4;
    }
    let widthMils = widthPt * 1000.0 / 72.0;
    let heightMils = heightPt * 1000.0 / 72.0;
    // 预定义纸张均为纵向定义，打印方向由 directionMode 单独控制，匹配时按纵向归一化比较
    let isPortrait = heightMils >= widthMils;
    let docWidthMils = isPortrait ? widthMils : heightMils;
    let docHeightMils = isPortrait ? heightMils : widthMils;
    let err = 20;
    for (let size of PREDEFINED_PAGE_SIZES) {
      if ((docWidthMils + err) >= size.widthMils && (docWidthMils - err) <= size.widthMils &&
        (docHeightMils + err) >= size.heightMils && (docHeightMils - err) <= size.heightMils) {
        return size.type;
      }
    }
    // 无匹配的预定义纸张：按文档实际尺寸构造自定义纸张（1 mil = 0.0254 mm，保留 1 位小数）
    let customSize: print.PrintPageSize = {
      id: 'custom_page_size',
      name: 'Custom',
      width: Math.round(docWidthMils * 0.0254 * 10) / 10,
      height: Math.round(docHeightMils * 0.0254 * 10) / 10
    };
    return customSize;
  }

  // 清理临时文件，忽略不存在的文件
  private cleanupTempFile(filePath: string): void {
    try {
      if (fs.accessSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch (e) {
      Log.e(TAG, 'cleanupTempFile error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
    }
  }

  // 清理 sharePdf 创建的临时文件（静态方法专用），忽略不存在的文件
  private static cleanupShareTempFile(filePath: string): void {
    try {
      if (fs.accessSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch (e) {
      Log.e(TAG, 'cleanupShareTempFile error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
    }
  }

  // 释放 PixelMap 原生内存（异步释放，不阻塞调用方同步流程）
  private releasePixelMap(pixelMap: image.PixelMap): void {
    pixelMap.release().then(() => {
      // 释放成功
    }).catch((e: Object) => {
      Log.e(TAG, 'releasePixelMap error: ' + JSON.stringify(e));
    });
  }
}