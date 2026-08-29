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
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:printing/src/preview/controller.dart';
import 'package:printing/src/preview/pdf_preview.dart';

/// Tests for [PdfPreviewState], [PdfPreviewData] and
/// [PdfPreviewController]: the state's exposed data and page-format
/// computation, the data notifier's locale-dependent defaults, and the
/// controller's notification contract.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PrintingPlatform.instance = _StateMockPlatform();
  });

  tearDown(() {
    PrintingPlatform.instance = _StateMockPlatform();
  });

  group('PdfPreviewState', () {
    testWidgets('should expose the preview data and computed page format',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (PdfPageFormat format) => Uint8List(0),
            ),
          ),
        ),
      );
      await tester.pump();

      final PdfPreviewState state =
          tester.state<PdfPreviewState>(find.byType(PdfPreview));

      expect(state.previewData, isA<PdfPreviewData>());
      // The default locale (en-US) picks the US-Letter page format.
      expect(state.computeActualPageFormat(), PdfPageFormat.letter);
      // The Printing.info() future from didChangeDependencies resolved.
      expect(state.infoLoaded, true);
    });

    testWidgets('build should return the controller-wrapped layout',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (PdfPageFormat format) => Uint8List(0),
            ),
          ),
        ),
      );

      final PdfPreviewState state =
          tester.state<PdfPreviewState>(find.byType(PdfPreview));
      final BuildContext context = tester.element(find.byType(PdfPreview));

      final Widget built = state.build(context);
      expect(built, isA<PdfPreviewController>());
    });

    testWidgets('computeActualPageFormat should honor an explicit initial '
        'page format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              initialPageFormat: PdfPageFormat.a4,
              build: (PdfPageFormat format) => Uint8List(0),
            ),
          ),
        ),
      );
      await tester.pump();

      final PdfPreviewState state =
          tester.state<PdfPreviewState>(find.byType(PdfPreview));
      expect(state.computeActualPageFormat(), PdfPageFormat.a4);
    });
  });

  group('PdfPreviewData', () {
    PdfPreviewData newData() => PdfPreviewData(
          buildDocument: (PdfPageFormat format) => Uint8List(0),
          pageFormats: const <String, PdfPageFormat>{
            'A4': PdfPageFormat.a4,
            'Letter': PdfPageFormat.letter,
          },
          onComputeActualPageFormat: () => PdfPageFormat.a4,
        );

    test('computedPageFormat should mirror the current page format', () {
      final PdfPreviewData data = newData();
      // ignore: deprecated_member_use_from_same_package
      expect(data.computedPageFormat, data.pageFormat);
      data.pageFormat = PdfPageFormat.letter;
      // ignore: deprecated_member_use_from_same_package
      expect(data.computedPageFormat, PdfPageFormat.letter);
    });

    testWidgets('localPageFormat should follow the device locale',
        (tester) async {
      final PdfPreviewData data = newData();

      // The test platform dispatcher defaults to en-US.
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      expect(data.localPageFormat, 'Letter');

      tester.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
      expect(data.localPageFormat, 'A4');

      // A locale without country code is treated as US territory.
      tester.platformDispatcher.localeTestValue = const Locale('de');
      expect(data.localPageFormat, 'Letter');

      tester.platformDispatcher.clearLocaleTestValue();
    });

    test('localPageFormat should pick the localized initial format', () {
      // With an en-US locale the constructor picks the 'Letter' entry even
      // though 'A4' is listed first.
      final PdfPreviewData data = PdfPreviewData(
        buildDocument: (PdfPageFormat format) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
          'Letter': PdfPageFormat.letter,
        },
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      expect(data.localPageFormat, anyOf('Letter', 'A4'));
      expect(
        data.pageFormat,
        anyOf(PdfPageFormat.a4, PdfPageFormat.letter),
      );
    });
  });

  group('PdfPreviewController', () {
    testWidgets('updateShouldNotify should always report no change',
        (tester) async {
      final PdfPreviewData first = PdfPreviewData(
        buildDocument: (PdfPageFormat format) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );
      final PdfPreviewData second = PdfPreviewData(
        buildDocument: (PdfPageFormat format) => Uint8List(0),
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        onComputeActualPageFormat: () => PdfPageFormat.a4,
      );

      final PdfPreviewController controller = PdfPreviewController(
        data: first,
        child: const SizedBox(),
      );
      final PdfPreviewController oldController = PdfPreviewController(
        data: second,
        child: const SizedBox(),
      );

      expect(controller.data, same(first));
      // The InheritedNotifier already notifies through the notifier, so the
      // widget-level updateShouldNotify deliberately returns false.
      expect(controller.updateShouldNotify(oldController), false);
    });
  });
}

class _StateMockPlatform extends Mock
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
