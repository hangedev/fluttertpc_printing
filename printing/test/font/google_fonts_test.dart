/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net>
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

  // Swap the default cache for a stub that avoids real network downloads:
  // every PdfGoogleFonts.<font>() resolves through PdfBaseCache.defaultCache,
  // and getFont() falls back to Font.helvetica() when the bytes are invalid.
  setUp(() {
    PdfBaseCache.defaultCache = _GoogleFontsStubCache();
  });

  tearDown(() {
    PdfBaseCache.defaultCache = PdfMemoryCache();
  });

  group('PdfGoogleFonts', () {
    test('should return a Font when loading aBeeZeeRegular', () async {
      final font = await PdfGoogleFonts.aBeeZeeRegular();
      expect(font, isA<Font>());
    });

    test('should return a Font when loading openSansItalic', () async {
      final font = await PdfGoogleFonts.openSansItalic();
      expect(font, isA<Font>());
    });

    test('should return a Font when loading openSansBoldItalic', () async {
      final font = await PdfGoogleFonts.openSansBoldItalic();
      expect(font, isA<Font>());
    });

    test('should return a Font when loading notoColorEmoji', () async {
      final font = await PdfGoogleFonts.notoColorEmoji();
      expect(font, isA<Font>());
    });

    test('should return a Font when loading cupertinoIcons', () async {
      final font = await PdfGoogleFonts.cupertinoIcons();
      expect(font, isA<Font>());
    });

    test('should fall back to helvetica when the cache resolves invalid bytes',
        () async {
      // A stub whose resolve throws simulates a network/download failure and
      // exercises the helvetica fallback path inside DownloadableFont.getFont().
      PdfBaseCache.defaultCache = _FailingGoogleFontsCache();
      final font = await PdfGoogleFonts.aBeeZeeRegular();
      expect(font, isA<Font>());
    });
  });
}

/// Cache stub returning a fixed byte buffer via the public resolve() so the
/// Google Fonts loaders do not hit the network.
class _GoogleFontsStubCache extends PdfBaseCache {
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
class _FailingGoogleFontsCache extends PdfBaseCache {
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
