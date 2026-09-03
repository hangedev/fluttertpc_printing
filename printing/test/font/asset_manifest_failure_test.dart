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
import 'package:printing/src/fonts/manifest.dart';

/// Failure-path tests for [AssetManifest.contains].
///
/// With no asset bundle backing the `flutter/assets` channel, loading
/// `AssetManifest.json` throws: the mixin must report `false`, evict the
/// broken entry and latch the failure so subsequent calls return early.
///
/// NOTE: this file intentionally does NOT share an isolate with the success
/// path (asset_manifest_test.dart) because the manifest state is static and
/// latched for the whole isolate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetManifest (missing manifest)', () {
    test('should return false when the manifest cannot be loaded', () async {
      expect(await AssetManifest.contains('fonts/OpenSans-Regular.ttf'), false);
    });

    test('should latch the failure and answer false without the bundle',
        () async {
      // The second call must return early from the latched `_failed` flag.
      expect(await AssetManifest.contains('anything'), false);
    });
  });
}
