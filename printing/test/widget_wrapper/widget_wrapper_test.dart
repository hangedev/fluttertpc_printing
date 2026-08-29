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
import 'package:printing/printing.dart';

/// WidgetWrapper is re-exported by the printing package via
/// package:pdf_widget_wrapper, so it is part of this library's public API.
///
/// The rasterizing paths (fromKey with a real RepaintBoundary and fromWidget
/// with bounded constraints) call RenderRepaintBoundary.toImage(), whose
/// native image decoding must run outside the widget test's microtask loop to
/// avoid hanging the test runner. Wrapping the rasterization in
/// tester.runAsync lets the live Skia pipeline complete in a headless run, so
/// the full public API (fromKey, fromWidget and the bytes property) is
/// exercised for real rather than skipped.
void main() {
  group('WidgetWrapper', () {
    testWidgets(
      'should return non-empty bytes when wrapping a widget via fromKey',
      (tester) async {
        final key = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: const SizedBox(width: 20, height: 20),
              ),
            ),
          ),
        );
        await tester.pump();

        final wrapper = await tester.runAsync(
          () => WidgetWrapper.fromKey(key: key, pixelRatio: 1.0),
        );

        expect(wrapper, isNotNull);
        expect(wrapper!.bytes, isA<Uint8List>());
        // 20x20 RGBA = 1600 bytes.
        expect(wrapper.bytes, hasLength(20 * 20 * 4));
      },
    );

    testWidgets(
      'should return non-empty bytes when wrapping a FlutterLogo via fromKey',
      (tester) async {
        final key = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: const FlutterLogo(size: 24),
              ),
            ),
          ),
        );
        await tester.pump();

        final wrapper = await tester.runAsync(
          () => WidgetWrapper.fromKey(key: key, pixelRatio: 1.0),
        );

        expect(wrapper, isNotNull);
        expect(wrapper!.bytes, isA<Uint8List>());
        expect(wrapper.bytes, isNotEmpty);
      },
    );

    testWidgets(
      'should return non-empty bytes when wrapping an arbitrary widget via fromWidget',
      (tester) async {
        BuildContext? capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(capturedContext, isNotNull);

        final wrapper = await tester.runAsync(
          () => WidgetWrapper.fromWidget(
            context: capturedContext!,
            widget: Container(
              color: Colors.white,
              constraints: const BoxConstraints(
                minWidth: 10,
                maxWidth: 20,
                minHeight: 10,
                maxHeight: 20,
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
            constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
            pixelRatio: 1.0,
          ),
        );

        expect(wrapper, isNotNull);
        expect(wrapper!.bytes, isNotEmpty);
      },
    );

    testWidgets(
      'should reject an unbounded widget when calling fromWidget',
      (tester) async {
        BuildContext? capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // fromWidget is async, so the unbounded-constraints rejection surfaces
        // as a failed Future. This path throws before any rasterization.
        await expectLater(
          WidgetWrapper.fromWidget(
            context: capturedContext!,
            widget: const SizedBox.shrink(),
            // Unbounded constraints: no maxWidth/maxHeight.
            constraints: const BoxConstraints(),
            pixelRatio: 1.0,
          ),
          throwsA(isA<Object>()),
        );
      },
    );
  });
}
