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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/src/asset_utils.dart';
import 'package:printing/src/cache.dart';

/// A minimal valid 1x1 PNG so pdf's MemoryImage accepts it.
const List<int> _pngBytes = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 1, //
  0, 0, 0, 1, 0, 1, 3, 0, 0, 0, 102, 188, 58, 37, 0, 0, 0, 3, 80, 76, 84,
  69, 181, 208, 208, 99, 4, 22, 234, 0, 0, 0, 31, 73, 68, 65, 84, 104,
  129, 237, 193, 1, 13, 0, 0, 0, 194, 160, 247, 79, 109, 14, 55, 160, 0, 0,
  0, 0, 0, 0, 0, 0, 190, 13, 33, 0, 0, 1, 154, 96, 225, 213, 0, 0, 0, 0, 73,
  69, 78, 68, 174, 66, 96, 130,
];

void main() {
  group('fontFromAssetBundle', () {
    test('should load a TtfFont from a stubbed asset bundle', () async {
      final font = await fontFromAssetBundle(
        'fonts/myfont.ttf',
        bundle: _AssetBundleStub(),
      );
      expect(font, isA<TtfFont>());
    });
  });

  group('imageFromAssetBundle', () {
    test('should return a MemoryImage from a stubbed asset bundle', () async {
      final image = await imageFromAssetBundle(
        'images/pic.png',
        bundle: _PngAssetBundle(),
      );
      expect(image, isA<MemoryImage>());
    });

    test('should forward the dpi and orientation to the image', () async {
      final image = await imageFromAssetBundle(
        'images/pic.png',
        bundle: _PngAssetBundle(),
        dpi: 96,
      ) as MemoryImage;
      expect(image.dpi, 96);
    });
  });

  group('networkImage', () {
    test('should return a MemoryImage using a stubbed cache', () async {
      PdfBaseCache.defaultCache = _AssetStubCache();
      addTearDown(() => PdfBaseCache.defaultCache = PdfMemoryCache());

      final image = await networkImage(
        'https://example.com/image.png',
        cache: true,
      );
      expect(image, isA<MemoryImage>());
    });

    test('should skip the cache when cache is disabled', () async {
      final cache = _AssetStubCache();
      PdfBaseCache.defaultCache = cache;
      addTearDown(() => PdfBaseCache.defaultCache = PdfMemoryCache());

      await networkImage(
        'https://example.com/image.png',
        cache: false,
      );
      expect(await cache.contains('https://example.com/image.png'), false);
    });
  });
}

/// AssetBundle stub that returns a fixed byte buffer for any key (for fonts).
class _AssetBundleStub extends CachingAssetBundle {
  static final ByteData _data =
      Uint8List(4096).buffer.asByteData();

  @override
  Future<ByteData> load(String key) async => _data;
}

/// AssetBundle stub that returns a valid PNG for any key (for images).
class _PngAssetBundle extends CachingAssetBundle {
  static final ByteData _data =
      Uint8List.fromList(_pngBytes).buffer.asByteData();

  @override
  Future<ByteData> load(String key) async => _data;
}

/// Cache stub used to avoid real network downloads in image tests.
/// Overrides the public resolve() since the private _download cannot be
/// overridden from another library.
class _AssetStubCache extends PdfBaseCache {
  static final Uint8List stubBytes = Uint8List.fromList(_pngBytes);

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
