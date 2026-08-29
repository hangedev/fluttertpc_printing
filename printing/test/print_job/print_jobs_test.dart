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
import 'package:pdf/pdf.dart';
import 'package:printing/src/print_job.dart';
import 'package:printing/src/raster.dart';

void main() {
  group('PrintJobs', () {
    test('add should return jobs with strictly increasing indexes', () {
      final PrintJobs jobs = PrintJobs();
      final PrintJob first = jobs.add();
      final PrintJob second = jobs.add();
      expect(first.index, lessThan(second.index));
    });

    test('getJob should return the previously added job', () {
      final PrintJobs jobs = PrintJobs();
      final Completer<bool> onCompleted = Completer<bool>();
      final PrintJob job = jobs.add(onCompleted: onCompleted);
      expect(jobs.getJob(job.index), same(job));
    });

    test('getJob should return null for an unknown index', () {
      final PrintJobs jobs = PrintJobs();
      expect(jobs.getJob(-1), isNull);
    });

    test('remove should drop the job from the list', () {
      final PrintJobs jobs = PrintJobs();
      final PrintJob job = jobs.add();
      expect(jobs.getJob(job.index), isNotNull);
      jobs.remove(job.index);
      expect(jobs.getJob(job.index), isNull);
    });

    test('remove should be a no-op for an unknown index', () {
      final PrintJobs jobs = PrintJobs();
      jobs.remove(999);
      expect(jobs.getJob(999), isNull);
    });
  });

  group('PrintJob', () {
    test('should keep the registered callbacks and index', () async {
      final PrintJobs jobs = PrintJobs();

      Uint8List layout(PdfPageFormat format) => Uint8List(0);
      final Completer<Uint8List> onHtmlRendered = Completer<Uint8List>();
      final Completer<bool> onCompleted = Completer<bool>();
      final StreamController<PdfRaster> onPageRasterized =
          StreamController<PdfRaster>();

      final PrintJob job = jobs.add(
        onLayout: layout,
        onHtmlRendered: onHtmlRendered,
        onCompleted: onCompleted,
        onPageRasterized: onPageRasterized,
      );

      expect(job.index, greaterThanOrEqualTo(0));
      expect(job.onLayout, same(layout));
      expect(job.onHtmlRendered, same(onHtmlRendered));
      expect(job.onCompleted, same(onCompleted));
      expect(job.onPageRasterized, same(onPageRasterized));

      // The stored completers are live and can be resolved.
      final Uint8List doc = Uint8List.fromList(<int>[1, 2, 3]);
      job.onHtmlRendered!.complete(doc);
      job.onCompleted!.complete(true);
      final PdfRaster raster =
          PdfRaster(2, 2, Uint8List.fromList(List<int>.filled(16, 0)));
      job.onPageRasterized!.add(raster);

      expect(await job.onHtmlRendered!.future, doc);
      expect(await job.onCompleted!.future, true);
      expect(await job.onPageRasterized!.stream.first, same(raster));

      await onPageRasterized.close();
    });

    test('useFFI should reflect the host platform', () {
      final PrintJobs jobs = PrintJobs();
      final PrintJob job = jobs.add();
      // The FFI side channel only exists on Apple platforms (see
      // platform_os.dart / method_channel_ffi.dart).
      expect(job.useFFI, Platform.isMacOS || Platform.isIOS);
    });

    test('callbacks should be optional', () {
      final PrintJobs jobs = PrintJobs();
      final PrintJob job = jobs.add();
      expect(job.onLayout, isNull);
      expect(job.onHtmlRendered, isNull);
      expect(job.onCompleted, isNull);
      expect(job.onPageRasterized, isNull);
    });
  });
}
