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

import 'dart:convert';

// `hide AssetManifest` avoids the clash between the framework's asset
// manifest class and the printing-local one under test.
import 'package:flutter/services.dart' hide AssetManifest;
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/fonts/manifest.dart';

/// Tests for [AssetManifest.contains] against a well-formed
/// `AssetManifest.json`.
///
/// The manifest is served through a mock handler on the `flutter/assets`
/// raw message channel, which is how `rootBundle` fetches assets in tests.
///
/// NOTE: [AssetManifest] latches static `_ready`/`_assets` state for the
/// lifetime of the isolate, so the failure path is covered by a dedicated
/// file (asset_manifest_failure_test.dart) to keep both deterministic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const manifestJson = '''
{
  "fonts/OpenSans-Regular.ttf": [
    "assets/fonts/OpenSans-Regular.ttf"
  ],
  "fonts/MaterialIcons-Regular.otf": [
    "assets/fonts/MaterialIcons-Regular.otf"
  ],
  "images/logo.png": [
    "assets/images/logo.png"
  ]
}
''';

  setUp(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
      );
      if (key == 'AssetManifest.json') {
        return ByteData.sublistView(utf8.encode(manifestJson));
      }
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('AssetManifest', () {
    test('should report an asset listed in the manifest', () async {
      expect(
        await AssetManifest.contains('fonts/OpenSans-Regular.ttf'),
        true,
      );
    });

    test('should report false for an asset missing from the manifest',
        () async {
      expect(await AssetManifest.contains('fonts/Unknown.ttf'), false);
      expect(await AssetManifest.contains(''), false);
    });

    test('should answer repeated queries from the loaded manifest',
        () async {
      expect(await AssetManifest.contains('images/logo.png'), true);
      expect(await AssetManifest.contains('images/logo.png'), true);
      expect(
        await AssetManifest.contains('fonts/MaterialIcons-Regular.otf'),
        true,
      );
    });
  });
}
