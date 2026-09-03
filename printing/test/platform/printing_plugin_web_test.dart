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

@TestOn('browser')
library;

import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js;
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/printing_web.dart';
import 'package:web/web.dart' as web;

/// Direct coverage of the web platform implementation [PrintingPlugin]
/// (lib/printing_web.dart), which cannot execute on the desktop VM test
/// host and is therefore skipped there.
///
/// Covered members:
/// - PrintingPlugin.info
/// - PrintingPlugin.layoutPdf
/// - PrintingPlugin.sharePdf
/// - PrintingPlugin.convertHtml
/// - PrintingPlugin.listPrinters
/// - PrintingPlugin.pickPrinter
/// - PrintingPlugin.raster
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final plugin = PrintingPlugin();

  group('PrintingPlugin web implementation', () {
    test('PrintingPlugin.info should report capabilities once pdf.js is '
        'available', () async {
      // PrintingPlugin.info lazily bootstraps pdf.js on first use. Installing
      // a stub whose GlobalWorkerOptions.workerSrc is configured makes
      // _hasPdfJsLib resolve true, so the CDN download inside _initPlugin is
      // skipped and the invocation completes fully offline.
      final workerOptions = js.JSObject()
        ..setProperty('workerSrc'.toJS, 'pdf.worker.min.js'.toJS);
      final pdfjsLib = js.JSObject()
        ..setProperty('GlobalWorkerOptions'.toJS, workerOptions);
      web.window.setProperty('pdfjsLib'.toJS, pdfjsLib);
      addTearDown(() {
        // This SDK's dart:js_interop_unsafe has no deleteProperty, so remove
        // the global through an eval, mirroring how the plugin itself probes
        // the window object.
        web.window.callMethod<js.JSBoolean>(
          'eval'.toJS,
          'delete window.pdfjsLib; true;'.toJS,
        );
      });

      final info = await plugin.info();
      expect(info.canPrint, isTrue, reason: 'PrintingPlugin.info canPrint');
      expect(info.canShare, isTrue, reason: 'PrintingPlugin.info canShare');
      expect(info.canRaster, isTrue, reason: 'PrintingPlugin.info canRaster');
    });

    test('PrintingPlugin.layoutPdf should return false for an empty document',
        () async {
      final printed = await plugin.layoutPdf(
        null,
        (PdfPageFormat format) async => Uint8List(0),
        'empty.pdf',
        PdfPageFormat.a4,
        true,
        false,
        OutputType.generic,
        false,
      );
      expect(printed, isFalse, reason: 'PrintingPlugin.layoutPdf');
    });

    test('PrintingPlugin.sharePdf should download the document and return true',
        () async {
      final shared = await plugin.sharePdf(
        Uint8List.fromList(<int>[1, 2, 3]),
        'shared.pdf',
        Rect.zero,
        null,
        null,
        null,
      );
      expect(shared, isTrue, reason: 'PrintingPlugin.sharePdf');
    });

    test('PrintingPlugin.convertHtml should be unimplemented on the web',
        () async {
      await expectLater(
        plugin.convertHtml('<b>bold</b>', null, PdfPageFormat.a4),
        throwsUnimplementedError,
        reason: 'PrintingPlugin.convertHtml',
      );
    });

    test('PrintingPlugin.listPrinters should be unimplemented on the web',
        () async {
      await expectLater(
        plugin.listPrinters(),
        throwsUnimplementedError,
        reason: 'PrintingPlugin.listPrinters',
      );
    });

    test('PrintingPlugin.pickPrinter should be unimplemented on the web',
        () async {
      await expectLater(
        plugin.pickPrinter(Rect.zero),
        throwsUnimplementedError,
        reason: 'PrintingPlugin.pickPrinter',
      );
    });

    test('PrintingPlugin.raster should expose the stream contract', () async {
      // raster() is an async* generator: invoking it returns the stream
      // immediately, and the pdf.js pipeline only starts once the stream is
      // listened to. Leaving it unlistened keeps this test offline while
      // still exercising the implementation entry point.
      final stream = plugin.raster(
        Uint8List.fromList(<int>[1, 2, 3]),
        const <int>[0],
        72,
      );
      expect(stream, isA<Stream<PdfRaster>>(), reason: 'PrintingPlugin.raster');
    });
  });
}
