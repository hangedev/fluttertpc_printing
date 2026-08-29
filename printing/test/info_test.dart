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
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  tearDown(() {
    // Mirror setUp for structural consistency: these tests only read const
    // data, so there is no global state to restore, but keep the pair
    // symmetric with the other test files.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PrintingInfo', () {
    test('should report all capabilities disabled when unavailable',
        () async {
      const info = PrintingInfo.unavailable;
      expect(info.canConvertHtml, false);
      expect(info.directPrint, false);
      expect(info.dynamicLayout, false);
      expect(info.canPrint, false);
      expect(info.canConvertHtml, false);
      expect(info.canShare, false);
      expect(info.canRaster, false);

      expect(info.toString(), isA<String>());
    });

    test('should honor explicit capability flags when constructed', () async {
      const info = PrintingInfo(
        directPrint: true,
        dynamicLayout: true,
        canPrint: true,
        canConvertHtml: true,
        canListPrinters: true,
        canShare: true,
        canRaster: true,
      );
      expect(info.directPrint, true);
      expect(info.dynamicLayout, true);
      expect(info.canPrint, true);
      expect(info.canConvertHtml, true);
      expect(info.canListPrinters, true);
      expect(info.canShare, true);
      expect(info.canRaster, true);
    });

    test('should populate only the flags present in a map via fromMap',
        () async {
      final info = PrintingInfo.fromMap(
        <dynamic, dynamic>{
          'canPrint': true,
        },
      );

      expect(info.canConvertHtml, false);
      expect(info.directPrint, false);
      expect(info.dynamicLayout, false);
      expect(info.canPrint, true);
      expect(info.canConvertHtml, false);
      expect(info.canShare, false);
      expect(info.canRaster, false);
    });
  });
}
