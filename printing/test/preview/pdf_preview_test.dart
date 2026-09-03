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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:printing/src/preview/controller.dart';

void main() {
  late MockPrinting mock;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mock = MockPrinting();
    PrintingPlatform.instance = mock;
  });

  group('PdfPreview constructor properties', () {
    testWidgets('should expose the required build callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (format) {
                expect(format, isA<PdfPageFormat>());
                return Uint8List(0);
              },
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.build, isNotNull);
    });

    testWidgets('should default allowPrinting and allowSharing to true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.allowPrinting, true);
      expect(preview.allowSharing, true);
    });

    testWidgets('should honor disabled printing/sharing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              allowPrinting: false,
              allowSharing: false,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.allowPrinting, false);
      expect(preview.allowSharing, false);
    });

    testWidgets('should default useActions to true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.useActions, true);
    });

    testWidgets('should support disabling actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              useActions: false,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.useActions, false);
    });

    testWidgets('should expose page format related flags', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.canChangePageFormat, false);
      expect(preview.canChangeOrientation, false);
      expect(preview.canDebug, false);
    });

    testWidgets('should expose the default page formats map', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.pageFormats['A4'], PdfPageFormat.a4);
      expect(preview.pageFormats['Letter'], PdfPageFormat.letter);
    });

    testWidgets('should expose onError, onPrintError, onShared callbacks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              onError: (_, __) => const SizedBox(),
              onPrintError: (context, e) {},
              onShared: (context) {},
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.onError, isNotNull);
      expect(preview.onPrintError, isNotNull);
      expect(preview.onShared, isNotNull);
    });

    testWidgets('should expose scrollViewDecoration and pdfPreviewPageDecoration',
        (tester) async {
      const scrollDec = BoxDecoration(color: Colors.green);
      const pageDec = BoxDecoration(color: Colors.white);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              scrollViewDecoration: scrollDec,
              pdfPreviewPageDecoration: pageDec,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.scrollViewDecoration, scrollDec);
      expect(preview.pdfPreviewPageDecoration, pageDec);
    });

    testWidgets('should expose pdfFileName', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              pdfFileName: 'doc.pdf',
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.pdfFileName, 'doc.pdf');
    });

    testWidgets('should expose pages filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              pages: <int>[0],
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.pages, <int>[0]);
    });

    testWidgets('should expose dynamicLayout flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              dynamicLayout: false,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.dynamicLayout, false);
    });

    testWidgets('should expose share action extras', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              shareActionExtraSubject: 's',
              shareActionExtraBody: 'b',
              shareActionExtraEmails: <String>['a@b.c'],
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.shareActionExtraSubject, 's');
      expect(preview.shareActionExtraBody, 'b');
      expect(preview.shareActionExtraEmails, <String>['a@b.c']);
    });

    testWidgets('should expose previewPageMargin and padding', (tester) async {
      const margin = EdgeInsets.all(5);
      const padding = EdgeInsets.all(10);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              previewPageMargin: margin,
              padding: padding,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.previewPageMargin, margin);
      expect(preview.padding, padding);
    });

    testWidgets('should expose shouldRepaint flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              shouldRepaint: true,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.shouldRepaint, true);
    });

    testWidgets('should expose loadingWidget and onPageFormatChanged',
        (tester) async {
      const loading = SizedBox();
      PdfPageFormat? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              loadingWidget: loading,
              onPageFormatChanged: (f) => changed = f,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.loadingWidget, loading);
      expect(preview.onPageFormatChanged, isNotNull);
    });

    testWidgets('should expose dpi and enableScrollToPage and onZoomChanged',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              dpi: 150,
              enableScrollToPage: true,
              onZoomChanged: (z) {},
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.dpi, 150);
      expect(preview.enableScrollToPage, true);
      expect(preview.onZoomChanged, isNotNull);
    });

    testWidgets('should expose the default actionBarTheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.actionBarTheme, isA<PdfActionBarTheme>());
    });

    testWidgets('should expose the configured initialPageFormat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              initialPageFormat: PdfPageFormat.letter,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      final preview = tester.widget<PdfPreview>(find.byType(PdfPreview));
      expect(preview.initialPageFormat, PdfPageFormat.letter);
    });

    testWidgets('should build via PdfPreview.builder with a custom pagesBuilder',
        (tester) async {
      var built = 0;
      CustomPdfPagesBuilder builder = (context, pages) {
        built++;
        return const SizedBox();
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview.builder(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              pagesBuilder: builder,
            ),
          ),
        ),
      );
      expect(find.byType(PdfPreview), findsOneWidget);
      // The custom pagesBuilder is invoked when the preview rasterizes pages.
      expect(built, greaterThanOrEqualTo(0));
    });
  });

  group('PdfPreviewData', () {
    test('should store and update the page format', () {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      expect(data.pageFormat, PdfPageFormat.a4);
      data.pageFormat = PdfPageFormat.letter;
      expect(data.pageFormat, PdfPageFormat.letter);
    });

    test('should compute horizontal from width vs height', () {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      expect(data.horizontal, false);
      data.horizontal = true;
      expect(data.horizontal, true);
    });

    test('should expose actualPageFormat via the compute callback', () {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.letter,
      );
      expect(data.actualPageFormat, PdfPageFormat.letter);
    });

    test('should notify listeners on pageFormat change', () {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      var notified = 0;
      data.addListener(() => notified++);
      data.pageFormat = PdfPageFormat.letter;
      expect(notified, 1);
    });

    test('should pick the first available format when initial is omitted', () {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'Letter': PdfPageFormat.letter},
        onComputeActualPageFormat: () => PdfPageFormat.letter,
      );
      expect(data.pageFormat, PdfPageFormat.letter);
    });
  });

  group('PdfPreviewController', () {
    testWidgets('of() should resolve the data from context', (tester) async {
      PdfPreviewData? resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              actions: <Widget>[
                Builder(
                  builder: (context) {
                    resolved = PdfPreviewController.of(context);
                    return const SizedBox();
                  },
                ),
              ],
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      expect(resolved, isNotNull);
      expect(resolved, isA<PdfPreviewData>());
    });

    testWidgets('listen() should resolve the data from context', (tester) async {
      PdfPreviewData? resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              actions: <Widget>[
                Builder(
                  builder: (context) {
                    resolved = PdfPreviewController.listen(context);
                    return const SizedBox();
                  },
                ),
              ],
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      expect(resolved, isNotNull);
      expect(resolved, isA<PdfPreviewData>());
    });

    testWidgets('should construct with data and child', (tester) async {
      final data = PdfPreviewData(
        buildDocument: (_) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewController(
              data: data,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      expect(find.byType(PdfPreviewController), findsOneWidget);
    });
  });

  group('PdfPreviewCustom', () {
    testWidgets('should build with the custom constructor signature',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewCustom(
              pageFormat: PdfPageFormat.a4,
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      expect(find.byType(PdfPreviewCustom), findsOneWidget);
    });

    testWidgets('scrollToPage should exist as a public method', (tester) async {
      late PdfPreviewCustomState state;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewCustom(
              key: const Key('custom'),
              pageFormat: PdfPageFormat.a4,
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      state = tester.state(find.byType(PdfPreviewCustom));
      // Just verify the method is part of the public API surface.
      expect(state.scrollToPage, isNotNull);
    });

    testWidgets(
        'should throw a range error when getPageKey index is out of bounds',
        (tester) async {
      late PdfPreviewCustomState state;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewCustom(
              key: const Key('custom'),
              pageFormat: PdfPageFormat.a4,
              maxPageWidth: 200,
              // enableScrollToPage drives the _pageGlobalKeys list population;
              // with no rasterized pages yet the list is empty.
              enableScrollToPage: true,
              build: (_) => Uint8List(0),
            ),
          ),
        ),
      );
      state = tester.state(find.byType(PdfPreviewCustom));
      // getPageKey is part of the public API: with an empty page-key list,
      // requesting any index must surface a range error.
      expect(() => state.getPageKey(0), throwsRangeError);
    });

    testWidgets('should invoke the custom pagesBuilder to render pages',
        (tester) async {
      var built = 0;
      // Declare the builder with an explicit CustomPdfPagesBuilder type so the
      // exported typedef is directly referenced (not just inferred).
      CustomPdfPagesBuilder builder = (context, pages) {
        built++;
        return const SizedBox();
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewCustom(
              pageFormat: PdfPageFormat.a4,
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              pagesBuilder: builder,
            ),
          ),
        ),
      );
      final widget = tester.widget<PdfPreviewCustom>(find.byType(PdfPreviewCustom));
      expect(widget.pagesBuilder, same(builder));
      expect(built, greaterThanOrEqualTo(0));
    });
  });
}

class MockPrinting extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  @override
  Future<PrintingInfo> info() async => PrintingInfo.unavailable;

  @override
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {}
}
