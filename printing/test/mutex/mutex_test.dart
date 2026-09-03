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
import 'package:printing/src/mutex.dart';

void main() {
  group('Mutex', () {
    test('should start unlocked', () {
      final Mutex mutex = Mutex();
      expect(mutex.locked, false);
    });

    test('acquire should lock and release should unlock', () async {
      final Mutex mutex = Mutex();
      await mutex.acquire();
      expect(mutex.locked, true);
      mutex.release();
      expect(mutex.locked, false);
    });

    test('wait should acquire and release immediately', () async {
      final Mutex mutex = Mutex();
      await mutex.wait();
      // wait() releases the mutex before returning, so the lock is free
      // again once the future completes.
      expect(mutex.locked, false);
    });

    test('a second acquire should queue until release hands over the lock',
        () async {
      final Mutex mutex = Mutex();
      await mutex.acquire();

      var acquired = false;
      final Future<void> second = mutex.acquire().then((_) {
        acquired = true;
      });

      await pumpEventQueue();
      expect(acquired, false, reason: 'the mutex is still held');
      expect(mutex.locked, true);

      mutex.release();
      await second;
      expect(acquired, true);
      expect(mutex.locked, true, reason: 'the queued waiter now owns the lock');

      mutex.release();
      expect(mutex.locked, false);
    });

    test('wait should block while the mutex is held', () async {
      final Mutex mutex = Mutex();
      await mutex.acquire();

      var passed = false;
      final Future<void> waiter = mutex.wait().then((_) {
        passed = true;
      });

      await pumpEventQueue();
      expect(passed, false);

      mutex.release();
      await waiter;
      expect(passed, true);
      // wait() released the lock again on its way out.
      expect(mutex.locked, false);
    });

    test('release should wake every queued waiter', () async {
      final Mutex mutex = Mutex();
      await mutex.acquire();

      var first = false;
      var second = false;
      final Future<void> f1 = mutex.acquire().then((_) {
        first = true;
      });
      final Future<void> f2 = mutex.acquire().then((_) {
        second = true;
      });

      await pumpEventQueue();
      expect(first, false);
      expect(second, false);

      mutex.release();
      await Future.wait(<Future<void>>[f1, f2]);
      expect(first, true);
      expect(second, true);
      expect(mutex.locked, true);
    });

    test('should serialize concurrent critical sections', () async {
      final Mutex mutex = Mutex();
      final log = <String>[];

      Future<void> task(String name) async {
        await mutex.acquire();
        try {
          log.add('$name-enter');
          await Future<void>.delayed(Duration.zero);
          log.add('$name-exit');
        } finally {
          mutex.release();
        }
      }

      await Future.wait(<Future<void>>[task('a'), task('b')]);
      expect(log, <String>['a-enter', 'a-exit', 'b-enter', 'b-exit']);
    });
  });
}
