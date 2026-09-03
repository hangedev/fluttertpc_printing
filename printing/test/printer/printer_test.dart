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
import 'package:printing/printing.dart';

void main() {
  group('Printer', () {
    test('should use the url as name when name is omitted', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.url, 'ipp://localhost');
      expect(printer.name, 'ipp://localhost');
    });

    test('should keep an explicit display name', () {
      const printer = Printer(url: 'ipp://localhost', name: 'Office');
      expect(printer.name, 'Office');
    });

    test('should default model to null', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.model, isNull);
    });

    test('should store the provided model', () {
      const printer = Printer(url: 'ipp://localhost', model: 'LaserJet');
      expect(printer.model, 'LaserJet');
    });

    test('should default location to null', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.location, isNull);
    });

    test('should store the provided location', () {
      const printer = Printer(url: 'ipp://localhost', location: 'Floor 3');
      expect(printer.location, 'Floor 3');
    });

    test('should default comment to null', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.comment, isNull);
    });

    test('should store the provided comment', () {
      const printer = Printer(url: 'ipp://localhost', comment: 'Shared');
      expect(printer.comment, 'Shared');
    });

    test('should default isDefault to false', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.isDefault, false);
    });

    test('should accept an explicit isDefault flag', () {
      const printer = Printer(url: 'ipp://localhost', isDefault: true);
      expect(printer.isDefault, true);
    });

    test('should default isAvailable to true', () {
      const printer = Printer(url: 'ipp://localhost');
      expect(printer.isAvailable, true);
    });

    test('should accept an explicit isAvailable flag', () {
      const printer = Printer(url: 'ipp://localhost', isAvailable: false);
      expect(printer.isAvailable, false);
    });

    test('should build from a map using Printer.fromMap', () {
      final printer = Printer.fromMap(<dynamic, dynamic>{
        'url': 'ipp://host',
        'name': 'HP',
        'model': 'M1000',
        'location': 'HQ',
        'comment': 'fast',
        'default': true,
        'available': false,
      });
      expect(printer.url, 'ipp://host');
      expect(printer.name, 'HP');
      expect(printer.model, 'M1000');
      expect(printer.location, 'HQ');
      expect(printer.comment, 'fast');
      expect(printer.isDefault, true);
      expect(printer.isAvailable, false);
    });

    test('should fall back to url when fromMap omits name', () {
      final printer = Printer.fromMap(<dynamic, dynamic>{'url': 'ipp://h'});
      expect(printer.name, 'ipp://h');
    });

    test('should serialize to a map with toMap', () {
      const printer = Printer(
        url: 'ipp://host',
        name: 'HP',
        model: 'M1000',
        location: 'HQ',
        comment: 'fast',
        isDefault: true,
        isAvailable: false,
      );
      final map = printer.toMap();
      expect(map['url'], 'ipp://host');
      expect(map['name'], 'HP');
      expect(map['model'], 'M1000');
      expect(map['location'], 'HQ');
      expect(map['comment'], 'fast');
      expect(map['default'], true);
      expect(map['available'], false);
    });

    test('should round-trip through fromMap and toMap', () {
      const original = Printer(
        url: 'ipp://host',
        name: 'HP',
        model: 'M1000',
        location: 'HQ',
        comment: 'fast',
        isDefault: true,
        isAvailable: false,
      );
      final restored = Printer.fromMap(original.toMap());
      expect(restored.url, original.url);
      expect(restored.name, original.name);
      expect(restored.model, original.model);
      expect(restored.location, original.location);
      expect(restored.comment, original.comment);
      expect(restored.isDefault, original.isDefault);
      expect(restored.isAvailable, original.isAvailable);
    });

    test('should produce a human readable toString', () {
      const printer = Printer(url: 'ipp://host', name: 'HP');
      final str = printer.toString();
      expect(str, contains('HP'));
      expect(str, contains('ipp://host'));
    });
  });
}
