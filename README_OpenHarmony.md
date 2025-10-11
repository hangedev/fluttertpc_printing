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
      url: https://gitcode.com/openharmony-sig/fluttertpc_printing.git
      path: printing
      ref: br_printing-v5.14.2_ohos

```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [example](./printing/example/)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.27.5-ohos-0.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.1.0.828; ROM: 5.1.0.130 SP8;

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name                | return          | Description                                                                                                             | Type     | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| flutterImageProvider(ImageProvider<Object> image, {ImageConfiguration? configuration, ImageErrorListener? onError})  | Future<ImageProvider> | Loads an image from a Flutter ImageProvider into an ImageProvider instance. | function | yes               |
| fontFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfBaseCache? pdfCache, bool protect = false}) |  Future<TtfFont> | Loads a font from an asset bundle key. If used multiple times with the same font name, it will be included multiple times in the pdf file. | function | yes               |
| imageFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache}) | Future<ImageProvider> | Load an image from an asset bundle key. | function | yes               |
| networkImage(String url, {bool cache = true, Map<String, String>? headers, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache}) | Future<ImageProvider> | Download an image from the network. | function | yes               |

## Parameters

| Name        | Type                  | Description       | ohos Support |
|-------------|------------------------------|------------|--------------|
| key | String | Incoming fonts. | yes          |
| cache | bool | Font loading judgment. | yes          |
| protect | bool | Determine whether the font is duplicated. | yes          |
| image | ImageProvider<Object> | Input image. | yes          |
| url | String | Web Links url. | yes          |
| dpi | double | Sensitivity value. | yes          |

## 4. Known Issues

not

## 5. Others

## 6. License

This project is licensed under  [Apache-2.0 License](https://gitcode.com/openharmony-sig/fluttertpc_open_app_settings/blob/br_printing-v5.14.2_ohos/LICENSE) .

> Template version: v0.0.1