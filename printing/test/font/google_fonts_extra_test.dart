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

/// Parameterized coverage for the auto-generated [PdfGoogleFonts] loaders.
///
/// The class exposes 6525 static loaders that all share the same generated
/// shape (`static Future<Font> name() => fontFromGoogleFonts(...)`); full
/// enumeration adds no signal, so this file drives a representative spread
/// of popular families through the same shared-cache stub used by
/// google_fonts_test.dart.
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PdfBaseCache.defaultCache = _StubGoogleFontsCache();
  });

  tearDown(() {
    PdfBaseCache.defaultCache = PdfMemoryCache();
  });

  group('PdfGoogleFonts (representative loaders)', () {
    final loaders = <String, Future<Font> Function()>{
      'robotoRegular': PdfGoogleFonts.robotoRegular,
      'robotoCondensedRegular': PdfGoogleFonts.robotoCondensedRegular,
      'latoRegular': PdfGoogleFonts.latoRegular,
      'montserratRegular': PdfGoogleFonts.montserratRegular,
      'notoSansRegular': PdfGoogleFonts.notoSansRegular,
      'interRegular': PdfGoogleFonts.interRegular,
      'firaCodeRegular': PdfGoogleFonts.firaCodeRegular,
      'cabinRegular': PdfGoogleFonts.cabinRegular,
      'merriweatherRegular': PdfGoogleFonts.merriweatherRegular,
      'oswaldRegular': PdfGoogleFonts.oswaldRegular,
      'playfairDisplayRegular': PdfGoogleFonts.playfairDisplayRegular,
      'poppinsRegular': PdfGoogleFonts.poppinsRegular,
      'ralewayRegular': PdfGoogleFonts.ralewayRegular,
      'rubikRegular': PdfGoogleFonts.rubikRegular,
      'ubuntuRegular': PdfGoogleFonts.ubuntuRegular,
    };

    for (final entry in loaders.entries) {
      test('should return a Font from ${entry.key}()', () async {
        final Font font = await entry.value();
        expect(font, isA<Font>());
      });
    }

    test('should resolve every representative loader against one cache',
        () async {
      for (final entry in loaders.entries) {
        final Font font = await entry.value();
        expect(font, isA<Font>());
      }
    });
  });
}

/// Cache stub returning a fixed byte buffer via the public resolve() so the
/// Google Fonts loaders do not hit the network.
class _StubGoogleFontsCache extends PdfBaseCache {
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
