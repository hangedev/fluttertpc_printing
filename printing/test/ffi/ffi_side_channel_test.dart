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

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/method_channel_ffi.dart';
import 'package:printing/src/print_job.dart';

/// Tests for the FFI side-channel top-level functions `setDocumentFfi` and
/// `setErrorFfi`.
///
/// The native symbols (`net_nfet_printing_set_document`,
/// `net_nfet_printing_set_error`) are only linked into the process on macOS
/// and iOS (`DynamicLibrary.process()`). On every other host the dynamic
/// library loader must refuse to open, which is the behavior asserted here.
void main() {
  group('FFI side channel', () {
    test('setDocumentFfi should throw on platforms without the symbols',
        () async {
      final PrintJobs jobs = PrintJobs();
      final PrintJob job = jobs.add(onCompleted: Completer<bool>());

      if (Platform.isMacOS || Platform.isIOS) {
        // On Apple hosts the symbols resolve from the process itself; the
        // call is expected to succeed and there is nothing to assert.
        return;
      }

      expect(
        () => setDocumentFfi(job, Uint8List.fromList(<int>[1, 2, 3])),
        throwsUnsupportedError,
      );
    });

    test('setErrorFfi should throw on platforms without the symbols', () async {
      final PrintJobs jobs = PrintJobs();
      final PrintJob job = jobs.add(onCompleted: Completer<bool>());

      if (Platform.isMacOS || Platform.isIOS) {
        return;
      }

      expect(
        () => setErrorFfi(job, 'generation failed'),
        throwsUnsupportedError,
      );
    });
  });
}
