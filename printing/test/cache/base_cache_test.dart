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

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:printing/src/cache.dart';

/// Tests for the [PdfBaseCache] contract exercised through a base-class
/// typed reference, covering the full CRUD surface and the shared
/// `resolve()` download-and-cache logic.
void main() {
  final PdfBaseCache savedDefault = PdfBaseCache.defaultCache;

  tearDown(() {
    PdfBaseCache.defaultCache = savedDefault;
  });

  group('PdfBaseCache', () {
    test('should default to a memory cache', () {
      expect(PdfBaseCache.defaultCache, isA<PdfMemoryCache>());
    });

    test('should allow swapping the default cache', () {
      final PdfBaseCache replacement = _MemoryBackedCache();
      PdfBaseCache.defaultCache = replacement;
      expect(PdfBaseCache.defaultCache, same(replacement));
    });

    test('should add, get, contains, remove and clear entries', () async {
      final PdfBaseCache cache = _MemoryBackedCache();
      final bytes = Uint8List.fromList(<int>[7, 7, 7]);

      await cache.add('key', bytes);

      expect(await cache.contains('key'), true);
      expect(await cache.get('key'), bytes);
      expect(await cache.contains('missing'), false);
      expect(await cache.get('missing'), isNull);

      await cache.remove('key');
      expect(await cache.contains('key'), false);

      await cache.add('a', bytes);
      await cache.add('b', bytes);
      await cache.clear();
      expect(await cache.contains('a'), false);
      expect(await cache.contains('b'), false);
    });

    test('resolve should serve a cache hit without downloading', () async {
      final PdfBaseCache cache = _MemoryBackedCache();
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      await cache.add('font.ttf', bytes);

      final result = await cache.resolve(
        name: 'font.ttf',
        uri: Uri.parse('https://fonts.example.com/font.ttf'),
      );

      expect(result, bytes);
    });

    test('resolve should download, store and return on a cache miss',
        () async {
      final PdfBaseCache cache = _MemoryBackedCache();
      final downloaded = Uint8List.fromList(<int>[9, 8, 7]);

      await http.runWithClient(
        () async {
          final result = await cache.resolve(
            name: 'new-font.ttf',
            uri: Uri.parse('https://fonts.example.com/new-font.ttf'),
          );
          expect(result, downloaded);
          expect(await cache.contains('new-font.ttf'), true);
          expect(await cache.get('new-font.ttf'), downloaded);
        },
        () => http_testing.MockClient(
          (http.BaseRequest request) async =>
              http.Response.bytes(downloaded, 200),
        ),
      );
    });

    test('resolve with cache disabled should not store the download',
        () async {
      final PdfBaseCache cache = _MemoryBackedCache();

      await http.runWithClient(
        () async {
          final result = await cache.resolve(
            name: 'once.ttf',
            uri: Uri.parse('https://fonts.example.com/once.ttf'),
            cache: false,
          );
          expect(result, hasLength(3));
          expect(await cache.contains('once.ttf'), false);
        },
        () => http_testing.MockClient(
          (http.BaseRequest request) async =>
              http.Response.bytes(<int>[1, 2, 3], 200),
        ),
      );
    });

    test('resolve should throw when the server answers a non-200 status',
        () async {
      final PdfBaseCache cache = _MemoryBackedCache();

      await http.runWithClient(
        () async {
          await expectLater(
            cache.resolve(
              name: 'gone.ttf',
              uri: Uri.parse('https://fonts.example.com/gone.ttf'),
            ),
            throwsA(isA<FlutterError>()),
          );
        },
        () => http_testing.MockClient(
          (http.BaseRequest request) async => http.Response('', 404),
        ),
      );
    });
  });
}

/// Minimal in-memory [PdfBaseCache] implementation used to exercise the
/// abstract contract through a base-class typed receiver.
class _MemoryBackedCache extends PdfBaseCache {
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
}
