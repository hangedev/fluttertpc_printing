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
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

void main() {
  group('PdfPreviewAction', () {
    testWidgets('should expose the configured icon and onPressed',
        (tester) async {
      var pressed = 0;
      // Wrapping inside PdfPreview so PdfPreviewController.of(context)
      // resolves when the action is pressed.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPreviewAction(
                  icon: const Icon(Icons.add),
                  onPressed: (context, build, format) => pressed++,
                ),
              ],
            ),
          ),
        ),
      );

      final action =
          tester.widget<PdfPreviewAction>(find.byType(PdfPreviewAction));
      expect((action.icon as Icon).icon, Icons.add);
      expect(action.onPressed, isNotNull);
    });

    testWidgets('should render an IconButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPreviewAction(
                  icon: const Icon(Icons.add),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should build a const instance with no callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                const PdfPreviewAction(
                  icon: Icon(Icons.add),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );
      final action =
          tester.widget<PdfPreviewAction>(find.byType(PdfPreviewAction));
      expect(action.onPressed, isNull);
    });
  });

  group('PdfPrintAction', () {
    testWidgets('should default jobName to Document', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[PdfPrintAction(onPrinted: () {})],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect(action.jobName, 'Document');
    });

    testWidgets('should keep an explicit jobName', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPrintAction(jobName: 'Report', onPrinted: () {}),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect(action.jobName, 'Report');
    });

    testWidgets('should expose dynamicLayout and usePrinterSettings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPrintAction(
                  dynamicLayout: false,
                  usePrinterSettings: true,
                  onPrinted: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect(action.dynamicLayout, false);
      expect(action.usePrinterSettings, true);
    });

    testWidgets('should expose onPrinted and onPrintError callbacks',
        (tester) async {
      var printed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPrintAction(
                  onPrinted: () => printed++,
                  onPrintError: (e) {},
                ),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect(action.onPrinted, isNotNull);
      expect(action.onPrintError, isNotNull);
    });

    testWidgets('should default icon to Icons.print', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[PdfPrintAction(onPrinted: () {})],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect((action.icon as Icon).icon, Icons.print);
    });

    testWidgets('should keep an explicit custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPrintAction(
                  icon: const Icon(Icons.print_outlined),
                  onPrinted: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfPrintAction>(find.byType(PdfPrintAction));
      expect((action.icon as Icon).icon, Icons.print_outlined);
    });
  });

  group('PdfShareAction', () {
    testWidgets('should default filename to document.pdf', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[PdfShareAction(onShared: () {})],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfShareAction>(find.byType(PdfShareAction));
      expect(action.filename, 'document.pdf');
    });

    testWidgets('should keep subject, body and emails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfShareAction(
                  filename: 'r.pdf',
                  subject: 's',
                  body: 'b',
                  emails: <String>['a@b.c'],
                  onShared: () {},
                  onShareError: (e) {},
                ),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfShareAction>(find.byType(PdfShareAction));
      expect(action.filename, 'r.pdf');
      expect(action.subject, 's');
      expect(action.body, 'b');
      expect(action.emails, <String>['a@b.c']);
      expect(action.onShared, isNotNull);
      expect(action.onShareError, isNotNull);
    });

    testWidgets('should default icon to Icons.share', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[PdfShareAction(onShared: () {})],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfShareAction>(find.byType(PdfShareAction));
      expect((action.icon as Icon).icon, Icons.share);
    });

    testWidgets('should keep an explicit custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfShareAction(
                  icon: const Icon(Icons.ios_share),
                  onShared: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final action = tester.widget<PdfShareAction>(find.byType(PdfShareAction));
      expect((action.icon as Icon).icon, Icons.ios_share);
    });
  });

  group('PdfPageFormatAction', () {
    testWidgets('should build a dropdown from the provided page formats',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[
                PdfPageFormatAction(
                  pageFormats: <String, PdfPageFormat>{
                    'A4': PdfPageFormat.a4,
                    'Letter': PdfPageFormat.letter,
                  },
                ),
              ],
            ),
          ),
        ),
      );
      // PdfPreview renders its own default PdfPageFormatAction, so at least
      // one is expected here; the dropdown it renders proves construction.
      expect(find.byType(PdfPageFormatAction), findsWidgets);
      expect(find.byType(DropdownButton<PdfPageFormat>), findsWidgets);
    });
  });

  group('PdfPageOrientationAction', () {
    testWidgets('should build a ToggleButtons widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreview(
              maxPageWidth: 200,
              build: (_) => Uint8List(0),
              actions: <Widget>[PdfPageOrientationAction()],
            ),
          ),
        ),
      );
      expect(find.byType(PdfPageOrientationAction), findsWidgets);
      expect(find.byType(ToggleButtons), findsWidgets);
    });
  });
}
