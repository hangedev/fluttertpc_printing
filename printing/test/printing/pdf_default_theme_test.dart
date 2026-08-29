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

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/cache.dart';

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('pdfDefaultTheme', () {
    setUp(() {
      // Reset global theme builder so each test starts from a clean state.
      ThemeData.buildThemeData = null;
      // Swap the default cache for a stub that avoids real network downloads;
      // PdfGoogleFonts resolves through PdfBaseCache.defaultCache.
      PdfBaseCache.defaultCache = _ThemeStubCache();
    });

    tearDown(() {
      ThemeData.buildThemeData = null;
      PdfBaseCache.defaultCache = PdfMemoryCache();
    });

    test('should register a ThemeData builder after invocation', () async {
      expect(ThemeData.buildThemeData, isNull);
      await pdfDefaultTheme();
      expect(ThemeData.buildThemeData, isNotNull);
    });

    test('should be idempotent when called twice', () async {
      await pdfDefaultTheme();
      final first = ThemeData.buildThemeData;
      await pdfDefaultTheme();
      expect(ThemeData.buildThemeData, same(first));
    });

    test('should produce a ThemeData instance from the registered builder',
        () async {
      await pdfDefaultTheme();
      final theme = ThemeData.buildThemeData!();
      expect(theme, isA<ThemeData>());
    });
  });
}

/// Cache stub returning a fixed byte buffer via the public resolve() so the
/// Google Fonts calls inside pdfDefaultTheme do not hit the network.
class _ThemeStubCache extends PdfBaseCache {
  static final Uint8List stubBytes = Uint8List(4096);

  final Map<String, Uint8List> _store = <String, Uint8List>{};

  @override
  Future<void> add(String key, Uint8List bytes) async {
    _store[key] = bytes;
  }

  @override
  Future<Uint8List?> get(String key) async => _store[key];

  @override
  Future<bool> contains(String key) async => _store.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<Uint8List> resolve({
    required String name,
    required Uri uri,
    bool cache = true,
    Map<String, String>? headers,
  }) async {
    if (cache && await contains(name)) {
      return (await get(name))!;
    }
    if (cache) {
      await add(name, stubBytes);
    }
    return stubBytes;
  }
}
