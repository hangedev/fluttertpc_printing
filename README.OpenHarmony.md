<p align="center">
  <h1 align="center"> <code>printing</code> </h1>
</p>


This project is based on [printing@5.14.2](https://pub.dev/packages/printing/versions/5.14.2).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  printing:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_printing.git
      path: printing
      # Please select the TAG to the TAG Version Mapping
      ref: TAG # Please select the TAG to the TAG Version Mapping
```

Execute Command

```bash
flutter pub get
```

#### TAG Version Mapping

| Flutter Framework Version | TAG                      | Branch                   |
|---------------------------|--------------------------|--------------------------|
| 3.7                       | 5.13.3-ohos-1.0.1-beta.1 | br_printing-5.13.2_ohos  |
| 3.22                      | 5.13.3-ohos-1.0.1-beta.1 | br_printing-5.13.2_ohos  |
| 3.27                      | 5.14.2-ohos-1.0.1        | br_printing-v5.14.2_ohos |
| 3.35                      | 5.14.2-ohos-1.0.1        | br_printing-v5.14.2_ohos |


<!-- tabs:end -->

### 1.2 OHOS Development Environment

Before using this library on the OHOS platform, set up the following development environment:

1. **Install DevEco Studio**: use the DevEco Studio version consistent with the [2.1 Compatibility](#21-compatibility) section.
2. **Configure the Flutter OHOS SDK**: install a Flutter OHOS branch (e.g. 3.27.5-ohos-0.0.1 or 3.35.8-ohos-0.0.1-canary1), verify with `flutter --version`.
3. **Configure CLI tools**: make sure `ohpm`, `hvigor` and `hdc` are on your PATH (usually under DevEco Studio's `tools/ohpm/bin` and the SDK directory).
4. **Run the example**: in the `demo/` directory of this repository (the OHOS example project) run `flutter pub get`, then `flutter run -d <ohos-device>` or `flutter build hap --debug`. `printing/example/` is the original upstream example and contains no OHOS project directory, so it cannot be built for OHOS.

### 1.3 Usage

For use cases, see [demo](./demo/) (the OHOS example project)

### 1.4 Quick Start

```dart
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// 1. Print a PDF via the onLayout callback
Future<void> printDocument() async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => buildPdfDocument(format),
    name: 'My Document',
    format: PdfPageFormat.a4,
  );
}

// 2. Share a PDF to other apps
Future<void> shareDocument(Uint8List pdfBytes) async {
  await Printing.sharePdf(
    bytes: pdfBytes,
    filename: 'document.pdf',
    bounds: Rect.zero,
  );
}

// 3. Rasterize a PDF to an image stream
Future<void> rasterDocument(Uint8List pdfBytes) async {
  await for (final page in Printing.raster(pdfBytes, pages: [1], dpi: 72)) {
    // page is a PdfRaster, convert it to an image
  }
}

// 4. Query platform capabilities
Future<void> queryCapabilities() async {
  final info = await Printing.info();
  print('canPrint: ${info.canPrint}, canShare: ${info.canShare}, canRaster: ${info.canRaster}');
}
```

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(17); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;
2. Flutter: 3.35.8-ohos-0.0.1-canary1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### 2.2 OHOS Platform Limitations

Due to system printing capabilities, some features are not supported on OHOS. Query runtime capabilities with `Printing.info()` before use:

| Capability (PrintingInfo) | OHOS Support | Description |
|---------------------------|:------------:|-------------|
| `canPrint` (print PDF) | yes | Print via the system print dialog |
| `dynamicLayout` (dynamic layout) | no | The print adapter does not re-trigger `onLayout` when the user changes print settings; the document is laid out once with the submitted page format |
| `canShare` (share PDF) | yes | Share via the system share panel |
| `canRaster` (rasterize) | yes | Convert PDF pages to an image stream |
| `directPrint` (direct print) | no | Cannot skip the dialog to print directly |
| `canConvertHtml` (HTML to PDF) | no | `convertHtml` is not available on OHOS |
| `canListPrinters` (list printers) | no | `listPrinters` is not available on OHOS |

> [!NOTE] `convertHtml`, `listPrinters`, `pickPrinter` and `directPrintPdf` are not available on the OHOS platform; calling them will throw an exception or return an empty result. Perform platform checks before use.

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### 3.1 Core API (Printing mixin)

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `Printing.layoutPdf({required LayoutCallback onLayout, String name, PdfPageFormat format, bool dynamicLayout, bool usePrinterSettings, OutputType outputType, bool forceCustomPrintPaper})` | `Future<bool>` | Print a PDF document via the system print dialog; the document is built once through the onLayout callback with the submitted page format (dynamic re-layout on setting changes is not supported on OHOS). Returns true on success, false if canceled | yes |
| `Printing.sharePdf({required Uint8List bytes, String filename, Rect? bounds, String? subject, String? body, List<String>? emails})` | `Future<bool>` | Share a PDF document to other apps (system share panel). bounds is the anchor rectangle for the share panel popup; defaults to a centered circle when null | yes |
| `Printing.raster(Uint8List document, {List<int>? pages, double dpi})` | `Stream<PdfRaster>` | Rasterize PDF pages into an image stream; pages specifies page numbers (null for all), dpi is the resolution (dots per inch). Both are named parameters | yes |
| `Printing.info()` | `Future<PrintingInfo>` | Query the printing capabilities of the current platform | yes |
| `Printing.directPrintPdf({required Printer printer, required LayoutCallback onLayout, String name, PdfPageFormat format, bool dynamicLayout, bool usePrinterSettings, OutputType outputType, bool forceCustomPrintPaper})` | `FutureOr<bool>` | Print directly to a specified printer (skip the dialog) | no |
| `Printing.listPrinters()` | `Future<List<Printer>>` | Enumerate the available printers on the system | no |
| `Printing.pickPrinter({required BuildContext context, Rect? bounds, String? title})` | `Future<Printer?>` | Open the native printer picker | no |
| `Printing.convertHtml({required String html, String? baseUrl, PdfPageFormat format = PdfPageFormat.standard})` | `Future<Uint8List>` | Convert an HTML document to PDF (deprecated, not supported on OHOS) | no |

### 3.2 Helper Classes and Enums

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `PrintingInfo` | class | Platform printing capability object with directPrint/dynamicLayout/canPrint/canConvertHtml/canListPrinters/canShare/canRaster fields; provides the `PrintingInfo()` constructor, the `PrintingInfo.fromMap(Map)` factory, and the `PrintingInfo.unavailable` static constant (all capabilities false) | yes |
| `Printer` | class | Printer information object. Fields: `url` (String, required), `name` (String), `model` (String?, printer model), `location` (String?, physical location), `comment` (String?, user comment), `isDefault` (bool), `isAvailable` (bool); provides the `Printer.fromMap(Map)` factory and `toString()` | partially (cannot enumerate/select, used as a data structure only) |
| `OutputType` | enum | Print output type: `generic` (default), `photo`, `grayscale`, `photoGrayscale` | partially (only default printing takes effect on OHOS) |
| `PdfRaster` | class | Rasterized page image data. Methods: `toImage()` returns `Future<ui.Image>`, `toPng()` returns `Future<Uint8List>` (PNG-encoded bytes); convertible to `ImageProvider` or `Uint8List` | yes |
| `PdfRasterImage` | class | `PdfRasterImage(PdfRaster raster)` wraps a `PdfRaster` as an `ImageProvider<PdfRaster>` so a rasterized page can be shown directly in an `Image` widget | yes |

### 3.3 Image/Font Helper Functions

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `flutterImageProvider(ImageProvider<Object> image, {ImageConfiguration? configuration, ImageErrorListener? onError})` | `Future<ImageProvider>` | Load a Flutter ImageProvider into a PdfImage-compatible image | yes |
| `fontFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfBaseCache? pdfCache, bool protect = false})` | `Future<TtfFont>` | Loads a font from an asset bundle key. If used multiple times with the same font name, it will be included multiple times in the pdf file. | yes |
| `imageFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache})` | `Future<ImageProvider>` | Load an image from an asset bundle key. | yes |
| `networkImage(String url, {bool cache = true, Map<String, String>? headers, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache})` | `Future<ImageProvider>` | Download an image from the network. | yes |

### 3.4 OHOS Native Interfaces (PrintingPlugin / PrintingJob)

The OHOS platform native implementation is located in `printing/ohos/`, based on the MethodChannel architecture:

- **`PrintingPlugin`**: implements `FlutterPlugin`, `AbilityAware` and `MethodCallHandler`. It registers the MethodChannel (`net.nfet.printing`), dispatches `printPdf`/`cancelJob`/`sharePdf`/`rasterPdf`/`printingInfo` method calls, and tracks the lifecycle of active print jobs.
- **`PrintingJob`**: the execution unit of a single print job, responsible for PDF file I/O, rasterization (based on `pdfService` from PDFKit), the system print adapter (`print.PrintDocumentAdapter`) and system sharing (`ShareController`).

### 3.5 Preview Widgets, Cache and Font Extension Interfaces

The following interfaces are cross-platform common features (Flutter UI/preview, font loading, caching); their behavior on OHOS matches iOS/Android, they are not OHOS-specific adaptations, and are listed together here:

| Name | return | Description | ohos Support |
|------|--------|-------------|:------------:|
| `PdfPreview` | Widget | PDF preview widget that renders the document produced by the onLayout callback in real time, with page zoom, paginated scrolling and an action bar | yes |
| `PdfPreviewCustom` | Widget | Custom-rendered PDF preview widget that allows a custom page builder (`CustomPdfPagesBuilder`) to control per-page drawing | yes |
| `PdfPreviewPageData` | class | Single preview page data object, holding the page bitmap, dimensions and other rendering info | yes |
| `PdfPreviewPage` | Widget | Single-page widget in the preview list, rendered from `PdfPreviewPageData` | yes |
| `PdfActionBarTheme` | class | Preview action bar theme configuration (colors, icons, etc.) | yes |
| `PdfPreviewAction` | class | Custom action item for the preview action bar, with an `icon` and an `OnPdfPreviewActionPressed` callback | yes |
| `PdfPrintAction` | class | Built-in "print" action (a `PdfPreviewAction` subclass) | yes |
| `PdfShareAction` | class | Built-in "share" action (a `PdfPreviewAction` subclass) | yes |
| `PdfPageFormatAction` | class | Built-in "page format" action (a `PdfPreviewAction` subclass) | yes |
| `PdfPageOrientationAction` | class | Built-in "page orientation" action (a `PdfPreviewAction` subclass) | yes |
| `OnPdfPreviewActionPressed` | typedef | Preview action callback signature: `void Function(BuildContext context, LayoutCallback build, PdfPageFormat pageFormat)` | yes |
| `CustomPdfPagesBuilder` | typedef | Custom page builder signature, used by `PdfPreviewCustom` | yes |
| `PdfBaseCache` | abstract class | Abstract base class for the PDF cache, defining the cache interface for assets/fonts/images. Core method `resolve({required String name, required Uri uri, bool cache = true, Map<String, String>? headers})`: returns `Future<Uint8List>`, reads from the cache first when `cache` is true and the cache hits, otherwise downloads from `uri` and writes back to the cache | yes |
| `PdfMemoryCache` | class | In-memory cache implementation based on `PdfBaseCache` | yes |
| `PdfGoogleFonts` | class | Built-in helper class that downloads TTF fonts  | yes |
| `DownloadableFont` | class | Downloadable font descriptor object, used by `PdfGoogleFonts`. Core method `getFont({PdfBaseCache? pdfCache, bool protect = false, Map<String, String>? headers, String assetPrefix, AssetBundle? bundle, bool cache = true})`: returns `Future<Font>`, loads from an asset first, otherwise downloads from the network | yes |
| `pdfDefaultTheme()` | `Future<void>` | Initializes the default theme used for PDF rendering (top-level async function, must be awaited) | yes |
| `WidgetWrapper` | class | ImageProvider that draws a Flutter Widget onto a PDF document. Re-exported from `package:pdf_widget_wrapper`. Provides `fromKey({required GlobalKey key, ...})` / `fromWidget(...)` static methods to capture a widget via a `RepaintBoundary`, and a `bytes` property holding the rasterized image | yes |
| `LayoutCallback` | typedef | Document builder callback signature: `FutureOr<Uint8List> Function(PdfPageFormat format)`. Used as the `onLayout` parameter of `Printing.layoutPdf` / `Printing.directPrintPdf`, and as the `build` parameter of `OnPdfPreviewActionPressed` | yes |

### 3.6 Parameters

The following parameters are common inputs of the image/font helper functions in 3.3 and the cache/font interfaces in 3.5; the owning interface of each is noted:

| Name | Type | Owning interface | Description | ohos Support |
|------|------|------------------|-------------|:------------:|
| key | String | `fontFromAssetBundle` / `imageFromAssetBundle` | Resource key in the asset bundle (font resource key or image resource key) | yes |
| cache | bool | `fontFromAssetBundle` / `imageFromAssetBundle` / `networkImage` / `PdfBaseCache.resolve` | Whether to use the cache: when true, reads from the cache first and, on a miss, downloads and writes back to the cache | yes |
| protect | bool | `fontFromAssetBundle` / `DownloadableFont.getFont` | Font deduplication flag: when true, a font with the same name is embedded only once in the PDF | yes |
| image | ImageProvider<Object> | `flutterImageProvider` | Flutter image provider to be loaded into a PdfImage | yes |
| url | String | `networkImage` | Download URL of the network image (image only, not a font) | yes |
| dpi | double | `imageFromAssetBundle` / `networkImage` | Resolution (Dots Per Inch), used to convert the image's physical size | yes |

## 4. Known Issues

None

## 5. Upgrade & Migration

When upgrading from an older version (e.g. 5.13.3-ohos-1.0.1-beta.1) to 5.14.2-ohos-1.0.1:

1. Update the `ref` in `pubspec.yaml` to the matching TAG (see the [TAG Version Mapping](#11-installation)).
2. Run `flutter pub get` to refresh dependencies.
3. Make sure the Flutter OHOS SDK version matches the TAG (3.27 and above use 5.14.2-ohos-1.0.1).
4. Note that `convertHtml`, `listPrinters` and `directPrintPdf` are still not supported on the OHOS platform.

## 6. License

This project is licensed under [Apache-2.0 License](https://gitcode.com/CPF-Flutter/fluttertpc_printing/blob/br_printing-v5.14.2_ohos/LICENSE) .

> Template version: v0.0.1