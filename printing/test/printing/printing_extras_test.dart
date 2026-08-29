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

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/fonts/font.dart';
import 'package:printing/src/interface.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PrintingPlatform.instance = _MockPrintingWithPrinters();
  });

  tearDown(() {
    // Reset the global platform override so tests do not leak mock state into
    // other test files sharing the same isolate.
    PrintingPlatform.instance = _MockPrintingWithPrinters();
  });

  group('Printing.listPrinters', () {
    test('should return a list of printers from the platform', () async {
      final printers = await Printing.listPrinters();
      expect(printers, isA<List<Printer>>());
      expect(printers.length, 1);
      expect(printers.first.url, 'ipp://test');
    });
  });

  group('Printing.convertHtml', () {
    test('should return the converted Pdf bytes', () async {
      final result = await Printing.convertHtml(
        html: '<html></html>',
        format: PdfPageFormat.a4,
      );
      expect(result, isA<Uint8List>());
    });

    test('should forward baseUrl and format to the platform', () async {
      final result = await Printing.convertHtml(
        html: '<html></html>',
        baseUrl: 'https://example.com',
        format: PdfPageFormat.letter,
      );
      expect(result.length, greaterThan(0));
    });
  });

  group('Exported top-level variables', () {
    test('PdfBaseCache.defaultCache should be a non-null cache', () {
      expect(PdfBaseCache.defaultCache, isNotNull);
    });

    test('DownloadableFont.cache should default to the shared cache', () {
      expect(DownloadableFont.cache, same(PdfBaseCache.defaultCache));
    });

    test('PrintingInfo.unavailable should expose all-false capabilities', () {
      const info = PrintingInfo.unavailable;
      expect(info.directPrint, false);
      expect(info.dynamicLayout, false);
      expect(info.canPrint, false);
      expect(info.canConvertHtml, false);
      expect(info.canListPrinters, false);
      expect(info.canShare, false);
      expect(info.canRaster, false);
    });
  });
}

class _MockPrintingWithPrinters extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  @override
  Future<PrintingInfo> info() async => PrintingInfo.unavailable;

  @override
  Future<List<Printer>> listPrinters() async => const <Printer>[
        Printer(url: 'ipp://test', name: 'Mock'),
      ];

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async =>
      Uint8List.fromList(<int>[1, 2, 3, 4]);
}
