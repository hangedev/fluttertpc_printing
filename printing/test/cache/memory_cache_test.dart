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

import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/src/cache.dart';

void main() {
  // The cache schedules a 20-minute auto-clear Timer on every add/get.
  // Run assertions inside FakeAsync so that Timer is owned by the zone and
  // never leaks as a real pending timer; we never advance the clock, so the
  // auto-clear callback never fires mid-test. The async bodies are driven to
  // completion via flushMicrotasks/flush.
  group('PdfMemoryCache', () {
    test('should store and retrieve bytes via add/get', () {
      Uint8List? result;
      fakeAsync((fakeAsync) {
        final cache = PdfMemoryCache();
        final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
        cache.add('key', bytes).then((_) => cache.get('key')).then((v) {
          result = v;
        });
        fakeAsync.flushMicrotasks();
      });
      expect(result, Uint8List.fromList(<int>[1, 2, 3, 4]));
    });

    test('should return null for a missing key via get', () {
      Uint8List? result;
      fakeAsync((fakeAsync) {
        final cache = PdfMemoryCache();
        cache.get('missing').then((v) {
          result = v;
        });
        fakeAsync.flushMicrotasks();
      });
      expect(result, isNull);
    });

    test('should report membership via contains', () {
      bool? before;
      bool? after;
      fakeAsync((fakeAsync) {
        final cache = PdfMemoryCache();
        cache.contains('key').then((v) {
          before = v;
          return cache.add('key', Uint8List(0));
        }).then((_) => cache.contains('key')).then((v) {
          after = v;
        });
        fakeAsync.flushMicrotasks();
      });
      expect(before, false);
      expect(after, true);
    });

    test('should remove a single entry via remove', () {
      bool? hasBefore;
      bool? hasAfter;
      Uint8List? valueAfter;
      fakeAsync((fakeAsync) {
        final cache = PdfMemoryCache();
        cache.add('key', Uint8List(0)).then((_) {
          return cache.contains('key');
        }).then((has) {
          hasBefore = has;
          return cache.remove('key');
        }).then((_) => cache.contains('key')).then((has) {
          hasAfter = has;
          return cache.get('key');
        }).then((v) {
          valueAfter = v;
        });
        fakeAsync.flushMicrotasks();
      });
      expect(hasBefore, true);
      expect(hasAfter, false);
      expect(valueAfter, isNull);
    });

    test('should wipe all entries via clear', () {
      bool? hasA;
      bool? hasB;
      fakeAsync((fakeAsync) {
        final cache = PdfMemoryCache();
        // Add two entries, then clear, then re-check both.
        cache
            .add('a', Uint8List(0))
            .then((_) => cache.add('b', Uint8List(0)))
            .then((_) => cache.clear())
            .then((_) => cache.contains('a'))
            .then((a) {
              hasA = a;
              return cache.contains('b');
            })
            .then((b) {
              hasB = b;
            });
        fakeAsync.flushMicrotasks();
      });
      expect(hasA, false);
      expect(hasB, false);
    });
  });
}
