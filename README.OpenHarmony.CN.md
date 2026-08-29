<p align="center">
  <h1 align="center"> <code>printing</code> </h1>
</p>


本项目基于 [printing@5.14.2](https://pub.dev/packages/printing/versions/5.14.2) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  printing:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_printing.git
      path: printing
      # ref: 请根据下方TAG版本对应表选择TAG
      ref: TAG # 请根据下方TAG版本对应表选择TAG
```

执行以下命令

```bash
flutter pub get
```

#### TAG 版本对应表

| Flutter 框架版本 | TAG                      | 分支                    |
|------------------|--------------------------|--------------------------|
| 3.7              | 5.13.3-ohos-1.0.1-beta.1 | br_printing-5.13.2_ohos  |
| 3.22             | 5.13.3-ohos-1.0.1-beta.1 | br_printing-5.13.2_ohos  |
| 3.27             | 5.14.2-ohos-1.0.1        | br_printing-v5.14.2_ohos |
| 3.35             | 5.14.2-ohos-1.0.1        | br_printing-v5.14.2_ohos |


<!-- tabs:end -->

### 1.2 OHOS 开发环境配置

在 OHOS 平台使用本库前，请先完成以下开发环境搭建：

1. **安装 DevEco Studio**：建议使用与 [2.1 兼容性](#21-兼容性) 章节一致的 DevEco Studio 版本。
2. **配置 Flutter OHOS SDK**：安装 Flutter OHOS 分支（如 3.27.5-ohos-0.0.1 或 3.35.8-ohos-0.0.1-canary1），执行 `flutter --version` 确认。
3. **配置命令行工具**：确保 `ohpm`、`hvigor`、`hdc` 已加入 PATH（通常位于 DevEco Studio 的 `tools/ohpm/bin` 与 SDK 目录下）。
4. **运行示例**：在本仓库的 `demo/` 目录（OHOS 示例工程）下执行 `flutter pub get`，随后执行 `flutter run -d <ohos设备>` 或 `flutter build hap --debug` 进行编译运行。`printing/example/` 为上游原始示例，未包含 OHOS 工程目录，不能用于 OHOS 编译。

### 1.3 使用案例

使用案例详见 [demo](./demo/)（OHOS 示例工程）

### 1.4 快速开始

```dart
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// 1. 打印 PDF：通过 onLayout 回调生成文档
Future<void> printDocument() async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => buildPdfDocument(format),
    name: 'My Document',
    format: PdfPageFormat.a4,
  );
}

// 2. 分享 PDF：将 PDF 字节数据（Uint8List）通过系统分享面板分享
Future<void> shareDocument(Uint8List pdfBytes) async {
  await Printing.sharePdf(
    bytes: pdfBytes,
    filename: 'document.pdf',
    bounds: Rect.zero,
  );
}

// 3. 光栅化 PDF：将 PDF 页面转为图片流
Future<void> rasterDocument(Uint8List pdfBytes) async {
  await for (final page in Printing.raster(pdfBytes, pages: [1], dpi: 72)) {
    // page 为 PdfRaster，可转为 image 使用
  }
}

// 4. 查询平台打印能力（用于判断 OHOS 平台支持哪些功能）
Future<void> queryCapabilities() async {
  final info = await Printing.info();
  print('canPrint: ${info.canPrint}, canShare: ${info.canShare}, canRaster: ${info.canRaster}');
}
```

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(17); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;
2. Flutter: 3.35.8-ohos-0.0.1-canary1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### 2.2 OHOS 平台能力限制

受系统打印能力限制，OHOS 平台对部分功能暂不支持。建议在调用前通过 `Printing.info()` 获取运行时能力信息：

| 能力 (PrintingInfo) | OHOS 支持 | 说明 |
|--------------------|:--------:|------|
| `canPrint`（打印 PDF） | yes | 通过系统打印对话框打印 |
| `dynamicLayout`（动态布局） | no | OHOS 打印适配器不会在用户更改设置时重新触发 `onLayout`，文档按提交的页面格式仅布局一次 |
| `canShare`（分享 PDF） | yes | 通过系统分享面板分享 |
| `canRaster`（光栅化） | yes | 将 PDF 页面转为图片流 |
| `directPrint`（直接打印） | no | 不支持跳过对话框直接打印 |
| `canConvertHtml`（HTML 转 PDF） | no | `convertHtml` 在 OHOS 上不可用 |
| `canListPrinters`（列出打印机） | no | `listPrinters` 在 OHOS 上不可用 |

> [!NOTE] `convertHtml`、`listPrinters`、`pickPrinter`、`directPrintPdf` 在 OHOS 平台不可用，调用会抛出异常或返回空结果，请在使用前做好平台判断。

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android。

### 3.1 核心 API（Printing 混入类）

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `Printing.layoutPdf({required LayoutCallback onLayout, String name, PdfPageFormat format, bool dynamicLayout, bool usePrinterSettings, OutputType outputType, bool forceCustomPrintPaper})` | `Future<bool>` | 通过系统打印对话框打印 PDF 文档，按提交的页面格式通过 onLayout 回调构建一次文档（OHOS 不支持用户更改设置时动态重新布局）。返回 true 表示打印成功，false 表示取消 | yes |
| `Printing.sharePdf({required Uint8List bytes, String filename, Rect? bounds, String? subject, String? body, List<String>? emails})` | `Future<bool>` | 通过系统分享面板分享 PDF 文档。bounds 为分享面板弹出的锚点矩形，为空时默认居中 | yes |
| `Printing.raster(Uint8List document, {List<int>? pages, double dpi})` | `Stream<PdfRaster>` | 将 PDF 页面光栅化为图片流，pages 指定页码（null 表示全部页），dpi 为分辨率（每英寸点数），均为命名参数 | yes |
| `Printing.info()` | `Future<PrintingInfo>` | 查询当前平台支持的打印能力 | yes |
| `Printing.directPrintPdf({required Printer printer, required LayoutCallback onLayout, String name, PdfPageFormat format, bool dynamicLayout, bool usePrinterSettings, OutputType outputType, bool forceCustomPrintPaper})` | `FutureOr<bool>` | 直接打印到指定打印机（跳过对话框） | no |
| `Printing.listPrinters()` | `Future<List<Printer>>` | 枚举系统可用打印机 | no |
| `Printing.pickPrinter({required BuildContext context, Rect? bounds, String? title})` | `Future<Printer?>` | 打开原生打印机选择器 | no |
| `Printing.convertHtml({required String html, String? baseUrl, PdfPageFormat format = PdfPageFormat.standard})` | `Future<Uint8List>` | 将 HTML 文档转换为 PDF（已废弃，OHOS 不支持） | no |

### 3.2 辅助类与枚举

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `PrintingInfo` | class | 平台打印能力信息对象，含 directPrint/dynamicLayout/canPrint/canConvertHtml/canListPrinters/canShare/canRaster 字段；提供 `PrintingInfo()` 构造函数、`PrintingInfo.fromMap(Map)` 工厂构造、以及 `PrintingInfo.unavailable` 静态常量（所有能力均为 false） | yes |
| `Printer` | class | 打印机信息对象。字段：`url`（String，必填）、`name`（String）、`model`（String?，打印机型号）、`location`（String?，物理位置）、`comment`（String?，用户备注）、`isDefault`（bool）、`isAvailable`（bool）；提供 `Printer.fromMap(Map)` 工厂构造与 `toString()` | partially（无法枚举/选择，仅作数据结构） |
| `OutputType` | enum | 打印输出类型：`generic`（默认）、`photo`（照片）、`grayscale`（灰度）、`photoGrayscale`（灰度照片） | partially（OHOS 仅默认打印生效） |
| `PdfRaster` | class | 光栅化后的页面图像数据。方法：`toImage()` 返回 `Future<ui.Image>`、`toPng()` 返回 `Future<Uint8List>`（PNG 编码字节数据），可转为 `ImageProvider` 或 `Uint8List` | yes |
| `PdfRasterImage` | class | `PdfRasterImage(PdfRaster raster)`，将 `PdfRaster` 包装为 `ImageProvider<PdfRaster>`，可直接用于 `Image` Widget 显示光栅化页面 | yes |

### 3.3 图片/字体辅助函数

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `flutterImageProvider(ImageProvider<Object> image, {ImageConfiguration? configuration, ImageErrorListener? onError})` | `Future<ImageProvider>` | 将 Flutter 中的 ImageProvider 加载为 PdfImage 可用的图像 | yes |
| `fontFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfBaseCache? pdfCache, bool protect = false})` | `Future<TtfFont>` | 从 asset bundle 键加载字体。如果使用相同的字体名称多次使用，它将在 PDF 文件中多次包含 | yes |
| `imageFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache})` | `Future<ImageProvider>` | 从 asset bundle 键加载图像 | yes |
| `networkImage(String url, {bool cache = true, Map<String, String>? headers, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache})` | `Future<ImageProvider>` | 从网络下载图像 | yes |

### 3.4 OHOS 原生接口（PrintingPlugin / PrintingJob）

OHOS 平台原生实现位于 `printing/ohos/`，基于 MethodChannel 架构：

- **`PrintingPlugin`**：实现 `FlutterPlugin`、`AbilityAware`、`MethodCallHandler`，负责注册 MethodChannel（`net.nfet.printing`），分发 `printPdf`/`cancelJob`/`sharePdf`/`rasterPdf`/`printingInfo` 等方法调用，并跟踪活跃打印任务生命周期。
- **`PrintingJob`**：单个打印任务的执行单元，负责 PDF 文件读写、光栅化（基于 PDFKit 的 `pdfService`）、系统打印适配器（`print.PrintDocumentAdapter`）、系统分享（`ShareController`）等。

### 3.5 预览 Widget、缓存与字体扩展接口

下列接口为跨平台通用功能（Flutter UI/预览、字体加载、缓存），OHOS 平台行为与 iOS/Android 一致，非 OHOS 特有适配，故统一在此列出：

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `PdfPreview` | Widget | PDF 预览组件，实时渲染 onLayout 回调生成的 PDF 文档，支持页面缩放、分页滚动与操作栏 | yes |
| `PdfPreviewCustom` | Widget | 自定义渲染的 PDF 预览组件，允许自定义页面构建器 `CustomPdfPagesBuilder` 控制每页绘制 | yes |
| `PdfPreviewPageData` | class | 预览单页数据对象，包含页面位图、尺寸等渲染信息 | yes |
| `PdfPreviewPage` | Widget | 预览列表中的单页 Widget，基于 `PdfPreviewPageData` 渲染 | yes |
| `PdfActionBarTheme` | class | 预览操作栏主题配置（颜色、图标等） | yes |
| `PdfPreviewAction` | class | 预览操作栏自定义动作项，含 `icon` 与 `OnPdfPreviewActionPressed` 回调 | yes |
| `PdfPrintAction` | class | 预置的“打印”动作（`PdfPreviewAction` 子类） | yes |
| `PdfShareAction` | class | 预置的“分享”动作（`PdfPreviewAction` 子类） | yes |
| `PdfPageFormatAction` | class | 预置的“页面格式”动作（`PdfPreviewAction` 子类） | yes |
| `PdfPageOrientationAction` | class | 预置的“页面方向”动作（`PdfPreviewAction` 子类） | yes |
| `OnPdfPreviewActionPressed` | typedef | 预览动作回调签名：`void Function(BuildContext context, LayoutCallback build, PdfPageFormat pageFormat)` | yes |
| `CustomPdfPagesBuilder` | typedef | 自定义页面构建器签名，用于 `PdfPreviewCustom` | yes |
| `PdfBaseCache` | abstract class | PDF 缓存抽象基类，定义 asset/字体/图片的缓存接口。核心方法 `resolve({required String name, required Uri uri, bool cache = true, Map<String, String>? headers})`：返回 `Future<Uint8List>`，优先从缓存读取（`cache` 为 true 且缓存命中），未命中则按 `uri` 下载并写入缓存 | yes |
| `PdfMemoryCache` | class | 基于 `PdfBaseCache` 的内存缓存实现 | yes |
| `PdfGoogleFonts` | class | 内置的字体下载辅助类 | yes |
| `DownloadableFont` | class | 可下载字体描述对象，用于 `PdfGoogleFonts`。核心方法 `getFont({PdfBaseCache? pdfCache, bool protect = false, Map<String, String>? headers, String assetPrefix, AssetBundle? bundle, bool cache = true})`：返回 `Future<Font>`，优先从 Asset 加载，否则从网络下载 | yes |
| `pdfDefaultTheme()` | `Future<void>` | 初始化适用于 PDF 渲染的默认主题（顶层异步函数，需 `await` 调用） | yes |
| `WidgetWrapper` | class | 将 Flutter Widget 绘制到 PDF 文档的 ImageProvider，自 `package:pdf_widget_wrapper` 重新导出。提供 `fromKey({required GlobalKey key, ...})` / `fromWidget(...)` 静态方法，通过 `RepaintBoundary` 捕获 Widget，并以 `bytes` 属性持有光栅化后的图像数据 | yes |
| `LayoutCallback` | typedef | 文档构建回调签名：`FutureOr<Uint8List> Function(PdfPageFormat format)`。作为 `Printing.layoutPdf` / `Printing.directPrintPdf` 的 `onLayout` 参数，以及 `OnPdfPreviewActionPressed` 的 `build` 参数 | yes |

### 3.6 参数说明

下列参数为 3.3 图片/字体辅助函数及 3.5 缓存/字体接口的公共入参，标注其所属接口：

| Name | Type | 所属接口 | Description | ohos Support |
|------|------|----------|-------------|:------------:|
| key | String | `fontFromAssetBundle` / `imageFromAssetBundle` | asset bundle 中的资源键名（字体资源键或图片资源键） | yes |
| cache | bool | `fontFromAssetBundle` / `imageFromAssetBundle` / `networkImage` / `PdfBaseCache.resolve` | 是否启用缓存：true 时优先读缓存，未命中再下载并写入缓存 | yes |
| protect | bool | `fontFromAssetBundle` / `DownloadableFont.getFont` | 是否对字体去重保护：true 时同名字体在 PDF 中只嵌入一次 | yes |
| image | ImageProvider<Object> | `flutterImageProvider` | 待加载为 PdfImage 的 Flutter 图像提供者 | yes |
| url | String | `networkImage` | 网络图片的下载地址（仅图片，非字体） | yes |
| dpi | double | `imageFromAssetBundle` / `networkImage` | 分辨率（每英寸点数，Dots Per Inch），用于换算图像物理尺寸 | yes |

## 4. 遗留问题

无

## 5. 升级迁移

从旧版本（如 5.13.3-ohos-1.0.1-beta.1）升级到 5.14.2-ohos-1.0.1 时：

1. 更新 `pubspec.yaml` 中的 `ref` 为对应 TAG（见 [TAG 版本对应表](#11-安装方式)）。
2. 执行 `flutter pub get` 刷新依赖。
3. 确认 Flutter OHOS SDK 版本与 TAG 匹配（3.27 及以上使用 5.14.2-ohos-1.0.1）。
4. 若使用 `convertHtml`、`listPrinters`、`directPrintPdf`，请注意这些在 OHOS 平台仍不支持。

## 6. 开源协议

本项目基于 [Apache-2.0开源协议](https://gitcode.com/CPF-Flutter/fluttertpc_printing/blob/br_printing-v5.14.2_ohos/LICENSE) ，请自由地享受和参与开源。



> 模板版本: v0.0.1