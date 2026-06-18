<p align="center">
  <h1 align="center"> <code>printing</code> </h1>
</p>


本项目基于 [printing@5.13.3](https://pub.dev/packages/printing/versions/5.13.3) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  printing_ohos:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_printing.git
      path: printing/ohos
      # ref: 5.14.2-ohos.1.0.0-beta.1
      ref: x.x.x-ohos-x.x.x-beta.x  # 请根据下方TAG版本对应表选择TAG
```

执行命令

```bash
flutter pub get
```

#### TAG 版本对应表

 | Flutter 框架版本 | TAG                      | 分支                  |
 |------|--------------------------|---------------------|
 | 3.7  | 5.13.3-ohos-1.0.1-beta.1 | [br_printing-5.13.2_ohos](https://gitcode.com/CPF-Flutter/fluttertpc_printing/tree/br_printing-5.13.2_ohos) |
 | 3.22 | 5.13.3-ohos-1.0.1-beta.1 | [br_printing-5.13.2_ohos](https://gitcode.com/CPF-Flutter/fluttertpc_printing/tree/br_printing-5.13.2_ohos) |
 | 3.27 | 5.14.2-ohos.1.0.0-beta.1 | [br_printing-v5.14.2_ohos](https://gitcode.com/CPF-Flutter/fluttertpc_printing/tree/br_printing-v5.14.2_ohos) |
 | 3.35 | 5.14.2-ohos.1.0.0-beta.1 | [br_printing-v5.14.2_ohos](https://gitcode.com/CPF-Flutter/fluttertpc_printing/tree/br_printing-v5.14.2_ohos) |

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [ohos/example](./printing/example/)

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. API

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

| Name                | return          | Description                                                                                                             | Type     | ohos Support |
|---------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-------------------|-------------------|
| flutterImageProvider(ImageProvider<Object> image, {ImageConfiguration? configuration, ImageErrorListener? onError}) |  Future<ImageProvider> | 将 Flutter 中的图片加载到实例ImageProviderImageProvider中 | function | yes               |
| fontFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfBaseCache? pdfCache, bool protect = false}) | Future<TtfFont> | 从 asset bundle 键加载字体。如果使用相同的字体名称多次使用，它将在 PDF 文件中多次包含 | function | yes               |
| imageFromAssetBundle(String key, {AssetBundle? bundle, bool cache = true, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache}) | Future<ImageProvider> | 从 asset bundle 键加载图像。 | function | yes               |
| networkImage(String url, {bool cache = true, Map<String, String>? headers, PdfImageOrientation? orientation, double? dpi, PdfBaseCache? pdfCache}) | Future<ImageProvider> | 从网络下载图像。 | function | yes               |

## Parameters

| Name        | Type                  | Description       | ohos Support |
|-------------|------------------------------|------------|--------------|
| key | String | 传入字体。 | yes          |
| cache | bool | 字体加载判断。 | yes          |
| protect | bool | 字体是否重复判断。 | yes          |
| image | ImageProvider<Object> | 传入图像。 | yes          |
| url | String | 网络链接。 | yes          |
| dpi | double | 灵敏度值。 | yes          |

## 4. 遗留问题

无

## 5. 其它

## 6. 开源协议

本项目基于 [Apache-2.0开源协议](https://gitcode.com/CPF-Flutter/fluttertpc_printing/blob/master/LICENSE) ，请自由地享受和参与开源。



> 模板版本: v0.0.1