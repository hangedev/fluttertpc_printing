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
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  tearDown(() {
    // The decoded test images enter the global image cache through
    // PdfRasterImage/toPng(); clear it so nothing leaks between tests.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('PdfRaster', () {
    test('should describe itself as an image with its dimensions and byte size',
        () async {
      final raster = PdfRaster(
          10, 10, Uint8List.fromList(List<int>.filled(10 * 10 * 4, 0)));
      expect(raster.toString(), 'Image 10x10 400 bytes');
      expect(await raster.toImage(), isA<ui.Image>());
      expect(await raster.toPng(), isA<Uint8List>());
    });
  });

  group('PdfRasterImage', () {
    testWidgets('should render as a Flutter Image widget',
        (WidgetTester tester) async {
      final raster = PdfRaster(
          10, 10, Uint8List.fromList(List<int>.filled(10 * 10 * 4, 0)));

      await tester.pumpWidget(Image(image: PdfRasterImage(raster)));
      await tester.pumpAndSettle();
    });

    test('should expose the source raster', () async {
      final raster = PdfRaster(
          10, 10, Uint8List.fromList(List<int>.filled(10 * 10 * 4, 0)));
      final provider = PdfRasterImage(raster);
      expect(provider.raster, same(raster));
      // obtainKey returns the same raster, enabling ImageProvider caching.
      expect(await provider.obtainKey(ImageConfiguration.empty), same(raster));
    });

    test('loadImage should return a completer for the decoded image',
        () async {
      final raster = PdfRaster(
          10, 10, Uint8List.fromList(List<int>.filled(10 * 10 * 4, 0)));
      final provider = PdfRasterImage(raster);

      // Drive the ImageProvider entry point used by the image cache: the
      // decode callback is ignored by this provider, which decodes the raw
      // RGBA buffer itself.
      final ImageStreamCompleter streamCompleter = provider.loadImage(
        raster,
        (ui.ImmutableBuffer buffer, {getTargetSize}) =>
            throw UnsupportedError('decode is unused'),
      );

      expect(streamCompleter, isA<ImageStreamCompleter>());

      final Completer<ImageInfo> inner = Completer<ImageInfo>();
      streamCompleter.addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
          if (!inner.isCompleted) {
            inner.complete(info);
          }
        }),
      );
      final ImageInfo info =
          await inner.future.timeout(const Duration(seconds: 5));
      expect(info.image.width, 10);
      expect(info.image.height, 10);
    });
  });
}
