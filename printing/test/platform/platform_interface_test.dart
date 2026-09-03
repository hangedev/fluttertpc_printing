/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:printing/src/method_channel.dart';

/// Tests for the [PrintingPlatform] platform-interface contract itself:
/// the default instance, instance swapping and the token check that
/// guards the interface.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Restore the default instance so later tests (and later files in this
    // isolate) start from a clean state.
    PrintingPlatform.instance = MethodChannelPrinting();
  });

  test('should default to the MethodChannel implementation', () {
    expect(PrintingPlatform.instance, isA<MethodChannelPrinting>());
  });

  test('should allow overriding the instance with a conforming implementation',
      () async {
    final fake = _RecordingPrintingPlatform();
    PrintingPlatform.instance = fake;

    expect(PrintingPlatform.instance, same(fake));

    // Drive the whole abstract surface through the base-class type.
    final PrintingPlatform platform = PrintingPlatform.instance;

    final info = await platform.info();
    expect(info.canPrint, true);
    expect(fake.calls, contains('info'));

    final printed = await platform.layoutPdf(
      null,
      (PdfPageFormat format) => Uint8List.fromList(<int>[1]),
      'doc',
      PdfPageFormat.a4,
      true,
      false,
      OutputType.generic,
      false,
    );
    expect(printed, true);
    expect(fake.calls, contains('layoutPdf'));

    final printers = await platform.listPrinters();
    expect(printers, hasLength(1));
    expect(fake.calls, contains('listPrinters'));

    final picked = await platform.pickPrinter(const Rect.fromLTWH(0, 0, 1, 1));
    expect(picked, isNull);
    expect(fake.calls, contains('pickPrinter'));

    final shared = await platform.sharePdf(
      Uint8List.fromList(<int>[1]),
      'doc.pdf',
      const Rect.fromLTWH(0, 0, 1, 1),
      null,
      null,
      null,
    );
    expect(shared, true);
    expect(fake.calls, contains('sharePdf'));

    final converted = await platform.convertHtml(
      '<html></html>',
      null,
      PdfPageFormat.a4,
    );
    expect(converted, hasLength(1));
    expect(fake.calls, contains('convertHtml'));

    final pages = await platform
        .raster(Uint8List.fromList(<int>[1]), null, 72)
        .toList();
    expect(pages, isEmpty);
    expect(fake.calls, contains('raster'));
  });

  test('should reject implementations that bypass the platform interface token',
      () {
    expect(
      () => PrintingPlatform.instance = _RoguePrintingPlatform(),
      throwsA(isA<AssertionError>()),
    );
  });
}

/// A conforming fake: it extends [PrintingPlatform] and therefore receives
/// the platform-interface token from the base constructor.
class _RecordingPrintingPlatform extends PrintingPlatform {
  final calls = <String>[];

  @override
  Future<PrintingInfo> info() async {
    calls.add('info');
    return const PrintingInfo(
      directPrint: true,
      dynamicLayout: true,
      canPrint: true,
      canConvertHtml: true,
      canListPrinters: true,
      canShare: true,
      canRaster: true,
    );
  }

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) async {
    calls.add('layoutPdf');
    return true;
  }

  @override
  Future<List<Printer>> listPrinters() async {
    calls.add('listPrinters');
    return const <Printer>[Printer(url: 'ipp://fake')];
  }

  @override
  Future<Printer?> pickPrinter(Rect bounds) async {
    calls.add('pickPrinter');
    return null;
  }

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) async {
    calls.add('sharePdf');
    return true;
  }

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async {
    calls.add('convertHtml');
    return Uint8List.fromList(<int>[1]);
  }

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {
    calls.add('raster');
  }
}

/// A rogue implementation: it only `implements` [PrintingPlatform], so it
/// never receives the interface token and must be rejected by the setter.
class _RoguePrintingPlatform implements PrintingPlatform {
  @override
  Future<PrintingInfo> info() => throw UnimplementedError();

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) => throw UnimplementedError();

  @override
  Future<List<Printer>> listPrinters() => throw UnimplementedError();

  @override
  Future<Printer?> pickPrinter(Rect bounds) => throw UnimplementedError();

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) => throw UnimplementedError();

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) => throw UnimplementedError();
}
