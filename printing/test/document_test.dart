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

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

late pw.Document doc;
pw.Font? ttf;

void main() {
  final path = Directory.current.path.split('/').last == 'test' ? '..' : '.';
  const channel = MethodChannel('net.nfet.printing');
  TestWidgetsFlutterBinding.ensureInitialized();

  // The font fixture lives outside this package (../pdf/open-sans.ttf) and is
  // not part of the published source tree; skip the document round-trip when
  // it is unavailable rather than failing the whole suite.
  final fontFile = File('$path/../pdf/open-sans.ttf');
  final hasFontFixture = fontFile.existsSync();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      // ignore: avoid_print
      print(methodCall);
      return '1';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('flutterImageProvider', () {
    test('should convert a FileImage into a Pdf image provider', () async {
      if (!hasFontFixture) {
        // ignore: avoid_print
        print('Skipping: ../pdf/open-sans.ttf fixture is not available');
        return;
      }
      final image =
          await flutterImageProvider(FileImage(File('$path/example.png')));

      doc.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Container(
              child: pw.Image(image),
            ),
          ),
        ),
      );
    });
  });

  setUpAll(() {
    pw.Document.debug = true;
    pw.RichText.debug = true;
    if (hasFontFixture) {
      final fontData = File('$path/../pdf/open-sans.ttf').readAsBytesSync();
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
    }
    doc = pw.Document();
  });

  tearDownAll(() async {
    if (!hasFontFixture) {
      return;
    }
    final file = File('printing.pdf');
    await file.writeAsBytes(await doc.save());
  });
}
