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

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/preview/page.dart';

void main() {
  group('PdfPreviewPageData', () {
    test('should store the image provider, width and height', () {
      final provider = MemoryImage(Uint8List.fromList(<int>[0]));
      final data = PdfPreviewPageData(
        image: provider,
        width: 100,
        height: 200,
      );
      expect(data.image, provider);
      expect(data.width, 100);
      expect(data.height, 200);
    });

    test('should compute width/height aspect ratio', () {
      final data = PdfPreviewPageData(
        image: MemoryImage(Uint8List.fromList(<int>[0])),
        width: 200,
        height: 100,
      );
      expect(data.aspectRatio, 2.0);
    });

    test('should return infinity when height is zero and width is positive',
        () {
      final data = PdfPreviewPageData(
        image: MemoryImage(Uint8List.fromList(<int>[0])),
        width: 200,
        height: 0,
      );
      expect(data.aspectRatio, double.infinity);
    });

    test('should be equal when all fields match', () {
      final provider = MemoryImage(Uint8List.fromList(<int>[1, 2, 3]));
      final a = PdfPreviewPageData(image: provider, width: 10, height: 20);
      final b = PdfPreviewPageData(image: provider, width: 10, height: 20);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('should not be equal when dimensions differ', () {
      final a = PdfPreviewPageData(
        image: MemoryImage(Uint8List.fromList(<int>[0])),
        width: 10,
        height: 20,
      );
      final b = PdfPreviewPageData(
        image: MemoryImage(Uint8List.fromList(<int>[0])),
        width: 11,
        height: 20,
      );
      expect(a == b, false);
    });
  });
}
