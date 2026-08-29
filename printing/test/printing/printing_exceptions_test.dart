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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';

/// Exception-driven scenarios for the [Printing] public API: printer state
/// failures (offline / unavailable), timeouts on stalled jobs, and missing
/// permissions. The platform layer is mocked so every failure is delivered
/// deterministically.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Reset the global platform override so no mock state leaks between files.
    PrintingPlatform.instance = _ThrowingPrintingPlatform();
  });

  group('Printing state exceptions (printer offline / unavailable)', () {
    test('should propagate a PRINTER_OFFLINE error from listPrinters',
        () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        listPrintersError: PlatformException(
          code: 'PRINTER_OFFLINE',
          message: 'The printer is offline',
        ),
      );

      await expectLater(
        Printing.listPrinters(),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'PRINTER_OFFLINE',
          ),
        ),
      );
    });

    test('should propagate a PRINTER_UNAVAILABLE error from layoutPdf',
        () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        layoutPdfError: PlatformException(
          code: 'PRINTER_UNAVAILABLE',
          message: 'The selected printer is no longer available',
        ),
      );

      await expectLater(
        Printing.layoutPdf(onLayout: (PdfPageFormat format) => Uint8List(0)),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'PRINTER_UNAVAILABLE',
          ),
        ),
      );
    });

    test('should propagate the printer error from directPrintPdf', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        layoutPdfError: PlatformException(
          code: 'PRINTER_UNAVAILABLE',
          message: 'device disconnected',
        ),
      );

      await expectLater(
        Printing.directPrintPdf(
          printer: const Printer(url: 'ipp://gone'),
          onLayout: (PdfPageFormat format) => Uint8List(0),
        ),
        throwsA(isA<PlatformException>()),
      );
    });

    test('should propagate a render failure from convertHtml', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        convertHtmlError: PlatformException(
          code: 'HTML_RENDER_FAILED',
          message: 'The html document could not be rendered',
        ),
      );

      await expectLater(
        // ignore: deprecated_member_use_from_same_package
        Printing.convertHtml(html: '<html></html>'),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'HTML_RENDER_FAILED',
          ),
        ),
      );
    });

    test('should report unavailable capabilities when the print subsystem is down',
        () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform();

      final info = await Printing.info();
      expect(info.canPrint, false);
      expect(info.canShare, false);
      expect(info.canRaster, false);
      expect(info.canListPrinters, false);
    });
  });

  group('Printing timeout exceptions (stalled jobs)', () {
    test('should time out when the print job never settles', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        hangLayoutPdf: true,
      );

      final Future<bool> job = Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => Uint8List(0),
      );

      // The call hangs forever; the caller must be able to bail out with a
      // timeout instead of waiting indefinitely.
      await expectLater(
        job.timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should time out when the raster stream never emits', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        hangRaster: true,
      );

      final Stream<PdfRaster> stream = Printing.raster(
        Uint8List.fromList(<int>[1, 2, 3]),
        dpi: 72,
      );

      await expectLater(
        stream.first.timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should surface a stalled html conversion through a timeout',
        () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        hangConvertHtml: true,
      );

      // ignore: deprecated_member_use_from_same_package
      final Future<Uint8List> future = Printing.convertHtml(
        html: '<html></html>',
      );

      await expectLater(
        future.timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('Printing permission exceptions', () {
    test('should propagate a PERMISSION_DENIED error from sharePdf', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        sharePdfError: PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Sharing requires the storage permission',
        ),
      );

      await expectLater(
        Printing.sharePdf(bytes: Uint8List.fromList(<int>[1])),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'PERMISSION_DENIED',
          ),
        ),
      );
    });

    test('should propagate a permission error from listPrinters', () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform(
        listPrintersError: PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Enumerating printers requires additional grants',
        ),
      );

      await expectLater(
        Printing.listPrinters(),
        throwsA(
          isA<PlatformException>().having(
            (PlatformException e) => e.code,
            'code',
            'PERMISSION_DENIED',
          ),
        ),
      );
    });

    test('should return null from pickPrinter when the picker is denied',
        () async {
      PrintingPlatform.instance = _ThrowingPrintingPlatform();

      // With unavailable capabilities the dialog path is skipped and the
      // platform picker result (null) is passed through.
      final printer = await Printing.pickPrinter(context: _MockContext());
      expect(printer, isNull);
    });
  });
}

class _MockContext extends Mock implements BuildContext {}

/// Mock platform whose every knob can be pointed at a failure mode.
class _ThrowingPrintingPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  _ThrowingPrintingPlatform({
    this.layoutPdfError,
    this.listPrintersError,
    this.sharePdfError,
    this.convertHtmlError,
    this.hangLayoutPdf = false,
    this.hangRaster = false,
    this.hangConvertHtml = false,
  });

  final PlatformException? layoutPdfError;
  final PlatformException? listPrintersError;
  final PlatformException? sharePdfError;
  final PlatformException? convertHtmlError;
  final bool hangLayoutPdf;
  final bool hangRaster;
  final bool hangConvertHtml;

  @override
  Future<PrintingInfo> info() async => PrintingInfo.unavailable;

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
    if (hangLayoutPdf) {
      // A job that never settles (printer stack hung / dialog stuck).
      await Completer<bool>().future;
      return false;
    }
    if (layoutPdfError != null) {
      throw layoutPdfError!;
    }
    return true;
  }

  @override
  Future<List<Printer>> listPrinters() async {
    if (listPrintersError != null) {
      throw listPrintersError!;
    }
    return const <Printer>[];
  }

  @override
  Future<Printer?> pickPrinter(Rect bounds) async => null;

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) async {
    if (sharePdfError != null) {
      throw sharePdfError!;
    }
    return true;
  }

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async {
    if (hangConvertHtml) {
      await Completer<Uint8List>().future;
    }
    if (convertHtmlError != null) {
      throw convertHtmlError!;
    }
    return Uint8List(0);
  }

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) {
    if (hangRaster) {
      return _NeverEmittingStream();
    }
    return const Stream<PdfRaster>.empty();
  }
}

/// A stream that never emits an event nor closes.
class _NeverEmittingStream extends Stream<PdfRaster> {
  final StreamController<PdfRaster> _controller = StreamController<PdfRaster>();

  @override
  StreamSubscription<PdfRaster> listen(
    void Function(PdfRaster event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
