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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/preview/action_bar_theme.dart';

void main() {
  group('PdfActionBarTheme', () {
    test('should expose default elevation and alignment values', () {
      const theme = PdfActionBarTheme();
      expect(theme.elevation, 4.0);
      expect(theme.actionSpacing, 0.0);
      expect(theme.alignment, WrapAlignment.spaceAround);
      expect(theme.runAlignment, WrapAlignment.center);
      expect(theme.crossAxisAlignment, WrapCrossAlignment.center);
    });

    test('should store the provided backgroundColor', () {
      const theme = PdfActionBarTheme(backgroundColor: Colors.black);
      expect(theme.backgroundColor, Colors.black);
    });

    test('should default backgroundColor to null', () {
      const theme = PdfActionBarTheme();
      expect(theme.backgroundColor, isNull);
    });

    test('should store the provided iconColor', () {
      const theme = PdfActionBarTheme(iconColor: Colors.white);
      expect(theme.iconColor, Colors.white);
    });

    test('should store the provided height', () {
      const theme = PdfActionBarTheme(height: 56);
      expect(theme.height, 56);
    });

    test('should store the provided textStyle', () {
      const style = TextStyle(fontSize: 14);
      const theme = PdfActionBarTheme(textStyle: style);
      expect(theme.textStyle, style);
    });

    test('should store a custom elevation', () {
      const theme = PdfActionBarTheme(elevation: 8);
      expect(theme.elevation, 8);
    });

    test('should store a custom actionSpacing', () {
      const theme = PdfActionBarTheme(actionSpacing: 12);
      expect(theme.actionSpacing, 12);
    });

    test('should store custom alignment values', () {
      const theme = PdfActionBarTheme(
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.start,
      );
      expect(theme.alignment, WrapAlignment.start);
      expect(theme.runAlignment, WrapAlignment.end);
      expect(theme.crossAxisAlignment, WrapCrossAlignment.start);
    });

    test('should copy with overrides while keeping others', () {
      const theme = PdfActionBarTheme();
      final copied = theme.copyWith(
        backgroundColor: Colors.red,
        height: 42,
        actionSpacing: 6,
      );
      expect(copied.backgroundColor, Colors.red);
      expect(copied.height, 42);
      expect(copied.actionSpacing, 6);
      expect(copied.elevation, theme.elevation);
    });

    test('should be equal when all fields match', () {
      const a = PdfActionBarTheme(
        backgroundColor: Colors.blue,
        height: 40,
        actionSpacing: 4,
      );
      const b = PdfActionBarTheme(
        backgroundColor: Colors.blue,
        height: 40,
        actionSpacing: 4,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('should not be equal when a field differs', () {
      const a = PdfActionBarTheme(height: 40);
      const b = PdfActionBarTheme(height: 41);
      expect(a == b, false);
    });
  });
}
