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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';

/// Exception / boundary / concurrency scenarios for the Printing public API.
///
/// These tests use a mock platform so the Dart-level parameter validation
/// (asserts, null/empty handling) and concurrent-call behavior can be verified
/// deterministically without a live print subsystem.
void main() {
  late _MockPrintingPlatform mock;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mock = _MockPrintingPlatform();
    PrintingPlatform.instance = mock;
  });

  tearDown(() {
    // Reset the global platform override so no mock state leaks between files.
    PrintingPlatform.instance = _MockPrintingPlatform();
  });

  group('Printing.raster parameter validation', () {
    test(
      'should throw an assertion error when dpi is zero',
      () async {
        // dpi > 0 is asserted at the Dart entry point (printing.dart).
        expect(
          () => Printing.raster(Uint8List(0), dpi: 0),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'should throw an assertion error when dpi is negative',
      () async {
        expect(
          () => Printing.raster(Uint8List(0), dpi: -1),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('Printing.raster boundary scenarios', () {
    test(
      'should produce a stream when document is an empty byte array',
      () async {
        // An empty document is a boundary input; the Dart layer must still
        // return a Stream (the platform decides whether to emit pages).
        final stream = Printing.raster(Uint8List(0), dpi: 72);
        expect(stream, isA<Stream<PdfRaster>>());
        // Drain the stream so any platform error surfaces here, not later.
        final pages = await stream.toList();
        expect(pages, isEmpty);
      },
    );

    test(
      'should accept a single-page filter and produce a stream',
      () async {
        final stream = Printing.raster(
          Uint8List.fromList(<int>[1, 2, 3]),
          pages: <int>[0],
          dpi: 72,
        );
        expect(stream, isA<Stream<PdfRaster>>());
        await stream.toList();
      },
    );

    test(
      'should accept an empty page filter list as "all pages"',
      () async {
        final stream = Printing.raster(
          Uint8List.fromList(<int>[1, 2, 3]),
          pages: <int>[],
          dpi: 72,
        );
        expect(stream, isA<Stream<PdfRaster>>());
        await stream.toList();
      },
    );

    test(
      'should accept a large dpi value without rejecting at the Dart layer',
      () async {
        final stream = Printing.raster(
          Uint8List.fromList(<int>[1, 2, 3]),
          dpi: 1200,
        );
        expect(stream, isA<Stream<PdfRaster>>());
        await stream.toList();
      },
    );
  });

  group('Printing.sharePdf boundary scenarios', () {
    test(
      'should return a bool when sharing an empty byte array',
      () async {
        // Empty bytes is a boundary input; the platform must not crash and
        // returns a deterministic bool rather than throwing.
        final result = await Printing.sharePdf(bytes: Uint8List(0));
        expect(result, isA<bool>());
      },
    );

    test(
      'should accept a custom filename and bounds',
      () async {
        final result = await Printing.sharePdf(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          filename: 'report.pdf',
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
        );
        expect(result, isA<bool>());
      },
    );
  });

  group('Printing concurrency', () {
    test(
      'should complete concurrent sharePdf and raster calls without error',
      () async {
        // Fire several platform calls concurrently to exercise the shared
        // platform instance under parallel load.
        final results =
            await Future.wait<bool>(<Future<bool>>[
          Printing.sharePdf(bytes: Uint8List.fromList(<int>[1])),
          Printing.sharePdf(bytes: Uint8List.fromList(<int>[2])),
          Printing.sharePdf(bytes: Uint8List.fromList(<int>[3])),
        ]);
        expect(results, <bool>[true, true, true]);
      },
    );

    test(
      'should complete a mix of concurrent print and raster calls',
      () async {
        final rasterStream = Printing.raster(
          Uint8List.fromList(<int>[1, 2, 3]),
          dpi: 72,
        );
        // Run raster draining concurrently with layoutPdf / sharePdf.
        final results = await Future.wait<dynamic>(<Future<dynamic>>[
          rasterStream.toList(),
          Printing.layoutPdf(
            onLayout: (_) => Uint8List.fromList(<int>[1, 2, 3]),
            name: 'doc',
            format: PdfPageFormat.a4,
          ),
          Printing.sharePdf(bytes: Uint8List.fromList(<int>[4, 5, 6])),
        ]);
        expect(results[0], isA<List<PdfRaster>>());
        expect(results[1], isA<bool>());
        expect(results[2], isA<bool>());
      },
    );
  });

  group('Printing.info capability state', () {
    test(
      'should expose the unavailable info when the platform reports so',
      () async {
        final info = await Printing.info();
        expect(info, isA<PrintingInfo>());
        expect(info.canRaster, false);
        expect(info.canPrint, false);
        expect(info.canShare, false);
      },
    );
  });
}

/// Mock platform that returns deterministic, non-throwing results so the
/// Dart-layer validation and concurrency can be tested in isolation.
class _MockPrintingPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
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
  ) async =>
      true;

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) async =>
      true;

  @override
  Future<Printer?> pickPrinter(Rect bounds) async => null;

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {}

  @override
  Future<List<Printer>> listPrinters() async => const <Printer>[];

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async =>
      Uint8List(0);
}
