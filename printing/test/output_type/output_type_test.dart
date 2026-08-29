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

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/output_type.dart';

void main() {
  group('OutputType', () {
    test('should expose exactly four enum values', () {
      expect(OutputType.values.length, 4);
    });

    test('should contain the generic value', () {
      expect(OutputType.values, contains(OutputType.generic));
    });

    test('should contain the photo value', () {
      expect(OutputType.values, contains(OutputType.photo));
    });

    test('should contain the grayscale value', () {
      expect(OutputType.values, contains(OutputType.grayscale));
    });

    test('should contain the photoGrayscale value', () {
      expect(OutputType.values, contains(OutputType.photoGrayscale));
    });

    test('should keep stable declaration order', () {
      expect(
        OutputType.values,
        <OutputType>[
          OutputType.generic,
          OutputType.photo,
          OutputType.grayscale,
          OutputType.photoGrayscale,
        ],
      );
    });

    test('should use enum index starting at zero', () {
      expect(OutputType.generic.index, 0);
      expect(OutputType.photo.index, 1);
      expect(OutputType.grayscale.index, 2);
      expect(OutputType.photoGrayscale.index, 3);
    });

    test('should parse a name back to the value', () {
      expect(OutputType.values.byName('generic'), OutputType.generic);
      expect(OutputType.values.byName('photo'), OutputType.photo);
      expect(OutputType.values.byName('grayscale'), OutputType.grayscale);
      expect(OutputType.values.byName('photoGrayscale'), OutputType.photoGrayscale);
    });
  });
}
