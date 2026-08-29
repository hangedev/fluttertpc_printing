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

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';

/// Tests exercising the `build`/`pressed` entry points of the preview
/// action widgets: [PdfPreviewAction], [PdfPrintAction], [PdfShareAction],
/// [PdfPageFormatAction] and [PdfPageOrientationAction].
///
/// The mocked platform reports unavailable capabilities so [PdfPreview]
/// does not inject its own print/share actions, keeping the finders below
/// unambiguous.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PrintingPlatform.instance = _ActionsMockPlatform();
  });

  tearDown(() {
    PrintingPlatform.instance = _ActionsMockPlatform();
  });

  group('PdfPreviewAction', () {
    testWidgets('build should return an IconButton', (tester) async {
      final PdfPreviewAction action = PdfPreviewAction(
        icon: const Icon(Icons.add),
        onPressed:
            (BuildContext context, LayoutCallback build, PdfPageFormat format) {},
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final Widget built = action.build(_contextOf(tester, Icons.add));
      expect(built, isA<IconButton>());
    });

    testWidgets('pressed should forward the preview data to onPressed',
        (tester) async {
      LayoutCallback? receivedBuild;
      PdfPageFormat? receivedFormat;

      final PdfPreviewAction action = PdfPreviewAction(
        icon: const Icon(Icons.add),
        onPressed: (BuildContext context, LayoutCallback build,
            PdfPageFormat pageFormat) {
          receivedBuild = build;
          receivedFormat = pageFormat;
        },
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      await action.pressed(_contextOf(tester, Icons.add));

      expect(receivedBuild, isNotNull);
      expect(receivedFormat, isA<PdfPageFormat>());
    });

    testWidgets('build should produce a disabled button without onPressed',
        (tester) async {
      const PdfPreviewAction action = PdfPreviewAction(
        icon: Icon(Icons.remove),
        onPressed: null,
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final IconButton button =
          action.build(_contextOf(tester, Icons.remove)) as IconButton;
      expect(button.onPressed, isNull);
    });
  });

  group('PdfPrintAction', () {
    testWidgets('build should return a PdfPreviewAction that prints',
        (tester) async {
      var printed = 0;

      final PdfPrintAction action = PdfPrintAction(
        onPrinted: () => printed++,
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final BuildContext context = _contextOf(tester, Icons.print);
      final Widget built = action.build(context);
      expect(built, isA<PdfPreviewAction>());

      // Driving the built PdfPreviewAction triggers the print flow through
      // the mocked platform and calls onPrinted.
      final PdfPreviewAction inner = built as PdfPreviewAction;
      await inner.pressed(context);
      await tester.pump();
      expect(printed, 1);
    });

    testWidgets('build should surface platform errors through onPrintError',
        (tester) async {
      PrintingPlatform.instance = _ActionsMockPlatform(failLayout: true);

      Object? reported;

      final PdfPrintAction action = PdfPrintAction(
        onPrinted: () {},
        onPrintError: (dynamic error) => reported = error,
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final BuildContext context = _contextOf(tester, Icons.print);

      // The error path reports through FlutterError; route it to a bucket
      // so the framework does not fail the test for an expected error.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        final Widget built = action.build(context);
        final PdfPreviewAction inner = built as PdfPreviewAction;
        await inner.pressed(context);
        await tester.pump();
      } finally {
        FlutterError.onError = originalOnError;
      }

      expect(reported, isA<PlatformException>());
    });
  });

  group('PdfShareAction', () {
    testWidgets('build should return a PdfPreviewAction that shares',
        (tester) async {
      var shared = 0;

      final PdfShareAction action = PdfShareAction(
        subject: 'subject',
        body: 'body',
        onShared: () => shared++,
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final BuildContext context = _contextOf(tester, Icons.share);
      final Widget built = action.build(context);
      expect(built, isA<PdfPreviewAction>());

      final PdfPreviewAction inner = built as PdfPreviewAction;
      await inner.pressed(context);
      // The share pipeline awaits layoutPdf and sharePdf before notifying;
      // pumping flushes those microtasks and the resulting frame.
      await tester.pump();
      await tester.pump();
      expect(shared, 1);
    });
  });

  group('PdfPageFormatAction', () {
    testWidgets('build should return a dropdown over the page formats',
        (tester) async {
      // PdfPreview itself renders a default PdfPageFormatAction; locate the
      // dropdown through its unique page-format map instead.
      const PdfPageFormatAction action = PdfPageFormatAction(
        pageFormats: <String, PdfPageFormat>{
          'Legal': PdfPageFormat.legal,
        },
      );

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final BuildContext context =
          tester.element(find.byType(PdfPageFormatAction).first);
      final Widget built = action.build(context);
      expect(built, isA<DropdownButton<PdfPageFormat>>());
      expect(find.byType(DropdownButton<PdfPageFormat>), findsWidgets);
    });
  });

  group('PdfPageOrientationAction', () {
    testWidgets('build should return a ToggleButtons widget', (tester) async {
      const PdfPageOrientationAction action = PdfPageOrientationAction();

      await tester.pumpWidget(_wrap(actions: <Widget>[action]));

      final BuildContext context =
          tester.element(find.byType(PdfPageOrientationAction).first);
      final Widget built = action.build(context);
      expect(built, isA<ToggleButtons>());
      expect(find.byType(ToggleButtons), findsWidgets);
    });
  });
}

Widget _wrap({required List<Widget> actions}) {
  return MaterialApp(
    home: Scaffold(
      body: PdfPreview(
        maxPageWidth: 200,
        actions: actions,
        build: (PdfPageFormat format) => Uint8List.fromList(<int>[1, 2, 3]),
      ),
    ),
  );
}

/// Locates the BuildContext below the action icon so controller lookups
/// resolve during `build`/`pressed` calls.
BuildContext _contextOf(WidgetTester tester, IconData icon) {
  return tester.element(find.byIcon(icon).first);
}

class _ActionsMockPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {
  _ActionsMockPlatform({this.failLayout = false});

  final bool failLayout;

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
    if (failLayout) {
      throw PlatformException(
        code: 'PRINT_FAILED',
        message: 'The print subsystem refused the job',
      );
    }
    return true;
  }

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
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {}

  @override
  Future<Printer?> pickPrinter(Rect bounds) async => null;

  @override
  Future<List<Printer>> listPrinters() async => const <Printer>[];

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async =>
      Uint8List.fromList(<int>[1]);
}
