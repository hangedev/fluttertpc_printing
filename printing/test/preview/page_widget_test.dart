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
import 'package:printing/src/preview/page.dart';

/// A minimal valid 1x1 PNG so the Flutter image codec can decode it.
const List<int> _pngBytes = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 1, //
  0, 0, 0, 1, 0, 1, 3, 0, 0, 0, 102, 188, 58, 37, 0, 0, 0, 3, 80, 76, 84,
  69, 181, 208, 208, 99, 4, 22, 234, 0, 0, 0, 31, 73, 68, 65, 84, 104,
  129, 237, 193, 1, 13, 0, 0, 0, 194, 160, 247, 79, 109, 14, 55, 160, 0, 0,
  0, 0, 0, 0, 0, 0, 190, 13, 33, 0, 0, 1, 154, 96, 225, 213, 0, 0, 0, 0, 73,
  69, 78, 68, 174, 66, 96, 130,
];

void main() {
  final pageData = PdfPreviewPageData(
    image: MemoryImage(Uint8List.fromList(_pngBytes)),
    width: 2,
    height: 1,
  );

  group('PdfPreviewPage', () {
    testWidgets('should render with the default decoration and margin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PdfPreviewPage(pageData: pageData)),
        ),
      );

      expect(find.byType(PdfPreviewPage), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('should apply a custom page decoration', (tester) async {
      const decoration = BoxDecoration(color: Colors.red);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewPage(
              pageData: pageData,
              pdfPreviewPageDecoration: decoration,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, decoration);
    });

    testWidgets('should apply a custom page margin', (tester) async {
      const margin = EdgeInsets.all(20);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfPreviewPage(pageData: pageData, pageMargin: margin),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.margin, margin);
    });

    testWidgets('should build without throwing when embedded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                PdfPreviewPage(pageData: pageData),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(PdfPreviewPage), findsOneWidget);
    });
  });
}
