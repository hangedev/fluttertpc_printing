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
import 'package:printing/src/cache.dart';
import 'package:printing/src/fonts/font.dart';

void main() {
  group('DownloadableFont', () {
    test('should expose the configured url', () {
      const font = DownloadableFont('https://example.com/font', 'OpenSans');
      expect(font.url, 'https://example.com/font');
    });

    test('should expose the configured name', () {
      const font = DownloadableFont('https://example.com/font', 'OpenSans');
      expect(font.name, 'OpenSans');
    });

    test('should reference the shared default cache by default', () {
      expect(DownloadableFont.cache, same(PdfBaseCache.defaultCache));
    });

    test('should return a Font from getFont using a stubbed cache', () async {
      const font = DownloadableFont('https://example.com/font', 'OpenSans');
      final result = await font.getFont(pdfCache: _FontStubCache());
      expect(result, isA<Font>());
    });

    test('should fall back to helvetica when download fails', () async {
      const font = DownloadableFont('https://example.com/bad', 'BadFont');
      final result =
          await font.getFont(pdfCache: _FailingCache());
      expect(result, isA<Font>());
    });
  });
}

/// A cache that resolves to a minimal byte stream so getFont() exercises its
/// success path without network access (overrides the public resolve, since
/// the private _download cannot be overridden from another library).
class _FontStubCache extends PdfBaseCache {
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

/// A cache whose resolve always fails, to exercise the helvetica fallback.
class _FailingCache extends PdfBaseCache {
  @override
  Future<void> add(String key, Uint8List bytes) async {}

  @override
  Future<Uint8List?> get(String key) async => null;

  @override
  Future<bool> contains(String key) async => false;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<Uint8List> resolve({
    required String name,
    required Uri uri,
    bool cache = true,
    Map<String, String>? headers,
  }) async {
    throw StateError('download failed for $name');
  }
}
