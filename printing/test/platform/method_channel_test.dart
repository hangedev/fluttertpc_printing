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

import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/method_channel.dart';

/// Tests for [MethodChannelPrinting], the MethodChannel-based platform
/// implementation of [PrintingPlatform].
///
/// Outgoing method calls (Dart -> platform) are intercepted with
/// `setMockMethodCallHandler`, and incoming callbacks (platform -> Dart,
/// e.g. `onLayout` / `onCompleted` / `onPageRasterized`) are simulated with
/// `handlePlatformMessage`, which routes encoded method calls to the handler
/// registered by the [MethodChannelPrinting] constructor.
///
/// The `onLayout` handler branches on `Platform.isOhos`; the OHOS Flutter
/// SDK declares that getter, but the desktop `flutter_tester` binary does
/// not implement it, so the call throws a [NoSuchMethodError] on desktop VM
/// hosts and the layout callback never runs there. Tests that deliver
/// `onLayout` probe for this and only assert the byte round-trip where the
/// handler can actually execute.
final bool isOhosGetterImplemented = () {
  try {
    return Platform.isOhos;
  } on NoSuchMethodError {
    return false;
  }
}();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('net.nfet.printing');
  const StandardMethodCodec codec = StandardMethodCodec();

  /// Recorded outgoing method calls, keyed by method name.
  final outgoing = <String, MethodCall>{};

  /// Values returned to the framework, keyed by method name.
  final replies = <String, Object?>{};

  setUp(() {
    outgoing.clear();
    replies.clear();
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      outgoing[call.method] = call;
      if (replies.containsKey(call.method)) {
        final reply = replies[call.method];
        if (reply is Exception) {
          throw reply;
        }
        return reply;
      }
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMessageHandler('net.nfet.printing', null);
  });

  /// Deliver a method call as if it came from the platform side and return
  /// the raw reply envelope produced by the registered Dart handler.
  Future<ByteData?> sendPlatformCall(String method, dynamic arguments) {
    return TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'net.nfet.printing',
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (ByteData? data) {},
    );
  }

  group('MethodChannelPrinting.info', () {
    test('should return the capabilities reported by the platform', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['printingInfo'] = <String, dynamic>{
        'canPrint': true,
        'canShare': true,
        'canRaster': true,
      };

      final info = await platform.info();
      expect(info.canPrint, true);
      expect(info.canShare, true);
      expect(info.canRaster, true);
      expect(outgoing.containsKey('printingInfo'), true);
    });

    test('should fall back to unavailable when the channel fails', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['printingInfo'] = PlatformException(code: 'UNAVAILABLE');

      final info = await platform.info();
      expect(info.canPrint, false);
      expect(info.canShare, false);
      expect(info.canRaster, false);
      expect(info.canListPrinters, false);
    });
  });

  group('MethodChannelPrinting.layoutPdf', () {
    test(
        'should forward the document bytes and complete when the job succeeds',
        () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      PdfPageFormat? requestedFormat;
      final future = platform.layoutPdf(
        null,
        (PdfPageFormat format) {
          requestedFormat = format;
          return Uint8List.fromList(<int>[1, 2, 3]);
        },
        'doc',
        PdfPageFormat.a4,
        true,
        false,
        OutputType.generic,
        false,
      );

      await pumpEventQueue();
      final call = outgoing['printPdf']!;
      expect(call.arguments is Map, true);
      expect(call.arguments['name'], 'doc');
      expect(call.arguments['width'], PdfPageFormat.a4.width);
      final int job = call.arguments['job'];

      // The platform asks the framework to build the document.
      final reply = await sendPlatformCall('onLayout', <String, dynamic>{
        'job': job,
        'width': 595.0,
        'height': 842.0,
        'marginLeft': 10.0,
        'marginTop': 20.0,
        'marginRight': 30.0,
        'marginBottom': 40.0,
      });
      if (isOhosGetterImplemented) {
        expect(
            codec.decodeEnvelope(reply!), Uint8List.fromList(<int>[1, 2, 3]));
        expect(requestedFormat!.width, closeTo(595.0, 0.01));
        expect(requestedFormat!.marginTop, closeTo(20.0, 0.01));
      } else {
        // Desktop VM host: `Platform.isOhos` is declared but not implemented
        // by flutter_tester, so the handler aborts with an error envelope
        // before invoking the layout callback.
        expect(
          () => codec.decodeEnvelope(reply!),
          throwsA(isA<PlatformException>()),
        );
      }

      // The platform reports completion; the job lifecycle itself is
      // host-independent.
      await sendPlatformCall('onCompleted', <String, dynamic>{
        'job': job,
        'completed': true,
      });
      expect(await future, true);
    });

    test('should complete with false when the job is canceled', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final future = platform.layoutPdf(
        null,
        (PdfPageFormat format) => Uint8List.fromList(<int>[9]),
        'doc',
        PdfPageFormat.a4,
        true,
        false,
        OutputType.generic,
        false,
      );

      await pumpEventQueue();
      final int job = outgoing['printPdf']!.arguments['job'];

      await sendPlatformCall('onCompleted', <String, dynamic>{
        'job': job,
        'completed': false,
      });
      expect(await future, false);
    });

    test('should surface the platform error when the job fails', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final future = platform.layoutPdf(
        null,
        (PdfPageFormat format) => Uint8List.fromList(<int>[9]),
        'doc',
        PdfPageFormat.a4,
        true,
        false,
        OutputType.generic,
        false,
      );

      await pumpEventQueue();
      final int job = outgoing['printPdf']!.arguments['job'];

      // Attach the expectation before completing with an error, otherwise
      // the error fires while the future still has no listener.
      final expectation = expectLater(future, throwsA('printer offline'));

      // The platform reports a failed job (e.g. the printer went offline).
      await sendPlatformCall('onCompleted', <String, dynamic>{
        'job': job,
        'completed': false,
        'error': 'printer offline',
      });
      await expectation;
    });

    test('should report a FlutterError when onLayout throws', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      FlutterErrorDetails? reported;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        reported = details;
      };

      final future = platform.layoutPdf(
        null,
        (PdfPageFormat format) => throw StateError('build failed'),
        'doc',
        PdfPageFormat.a4,
        true,
        false,
        OutputType.generic,
        false,
      );

      try {
        await pumpEventQueue();
        final int job = outgoing['printPdf']!.arguments['job'];

        final reply = await sendPlatformCall('onLayout', <String, dynamic>{
          'job': job,
          'width': 595.0,
          'height': 842.0,
          'marginLeft': 0.0,
          'marginTop': 0.0,
          'marginRight': 0.0,
          'marginBottom': 0.0,
        });

        // The handler answers with an error envelope instead of the
        // document bytes.
        expect(
          () => codec.decodeEnvelope(reply!),
          throwsA(isA<PlatformException>()),
        );
        if (isOhosGetterImplemented) {
          // The callback error was caught, reported through FlutterError and
          // rethrown into the envelope.
          expect(reported, isNotNull);
        } else {
          // Desktop VM host: the unimplemented `Platform.isOhos` getter
          // aborts the handler before the layout callback runs, so no
          // FlutterError is reported.
          expect(reported, isNull);
        }

        // The platform cancels the job afterwards; the layout call resolves
        // with `false` rather than throwing a second time.
        await sendPlatformCall('onCompleted', <String, dynamic>{
          'job': job,
          'completed': false,
        });
        expect(await future, false);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('MethodChannelPrinting.sharePdf', () {
    test('should return true when the platform shares the document',
        () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['sharePdf'] = 1;

      final result = await platform.sharePdf(
        Uint8List.fromList(<int>[1, 2, 3]),
        'document.pdf',
        const Rect.fromLTWH(0, 0, 10, 10),
        'subject',
        'body',
        <String>['a@b.c'],
      );

      expect(result, true);
      final call = outgoing['sharePdf']!;
      expect(call.arguments['name'], 'document.pdf');
      expect(call.arguments['subject'], 'subject');
      expect(call.arguments['body'], 'body');
      expect(call.arguments['emails'], <String>['a@b.c']);
    });

    test('should return false when the platform cancels the share', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['sharePdf'] = 0;

      final result = await platform.sharePdf(
        Uint8List.fromList(<int>[1]),
        'document.pdf',
        const Rect.fromLTWH(0, 0, 10, 10),
        null,
        null,
        null,
      );

      expect(result, false);
    });

    test('should propagate a permission PlatformException', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['sharePdf'] =
          PlatformException(code: 'PERMISSION_DENIED', message: 'denied');

      await expectLater(
        platform.sharePdf(
          Uint8List.fromList(<int>[1]),
          'document.pdf',
          const Rect.fromLTWH(0, 0, 10, 10),
          null,
          null,
          null,
        ),
        throwsA(
          isA<PlatformException>()
              .having((PlatformException e) => e.code, 'code', 'PERMISSION_DENIED'),
        ),
      );
    });
  });

  group('MethodChannelPrinting.listPrinters', () {
    test('should decode the printer list from the platform', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['listPrinters'] = <Map<dynamic, dynamic>>[
        <dynamic, dynamic>{
          'url': 'ipp://office',
          'name': 'Office',
          'default': true,
          'available': true,
        },
        <dynamic, dynamic>{'url': 'ipp://broken', 'available': false},
      ];

      final printers = await platform.listPrinters();

      expect(printers.length, 2);
      expect(printers.first.url, 'ipp://office');
      expect(printers.first.isDefault, true);
      expect(printers.first.isAvailable, true);
      expect(printers.last.name, 'ipp://broken');
      expect(printers.last.isAvailable, false);
    });

    test('should propagate a printer-state PlatformException', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['listPrinters'] =
          PlatformException(code: 'PRINTER_OFFLINE', message: 'offline');

      await expectLater(
        platform.listPrinters(),
        throwsA(
          isA<PlatformException>()
              .having((PlatformException e) => e.code, 'code', 'PRINTER_OFFLINE'),
        ),
      );
    });
  });

  group('MethodChannelPrinting.pickPrinter', () {
    test('should decode the selected printer from the platform', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['pickPrinter'] = <dynamic, dynamic>{
        'url': 'ipp://selected',
        'name': 'Selected',
      };

      final printer = await platform.pickPrinter(
        const Rect.fromLTWH(1, 2, 3, 4),
      );

      expect(printer, isNotNull);
      expect(printer!.url, 'ipp://selected');
      expect(printer.name, 'Selected');
      final call = outgoing['pickPrinter']!;
      expect(call.arguments['x'], 1.0);
      expect(call.arguments['w'], 3.0);
    });

    test('should return null when the user cancels the picker', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      replies['pickPrinter'] = null;

      final printer = await platform.pickPrinter(
        const Rect.fromLTWH(0, 0, 10, 10),
      );

      expect(printer, isNull);
    });
  });

  group('MethodChannelPrinting.convertHtml', () {
    test('should return the bytes delivered by onHtmlRendered', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final doc = Uint8List.fromList(<int>[4, 5, 6]);
      final future = platform.convertHtml(
        '<html></html>',
        null,
        PdfPageFormat.a4,
      );

      await pumpEventQueue();
      final call = outgoing['convertHtml']!;
      expect(call.arguments['html'], '<html></html>');
      final int job = call.arguments['job'];

      await sendPlatformCall('onHtmlRendered', <String, dynamic>{
        'job': job,
        'doc': doc,
      });

      expect(await future, doc);
    });

    test('should surface the error delivered by onHtmlError', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final future = platform.convertHtml(
        '<html></html>',
        'https://example.com',
        PdfPageFormat.a4,
      );

      await pumpEventQueue();
      final int job = outgoing['convertHtml']!.arguments['job'];

      // Attach the expectation before completing with an error, otherwise
      // the error fires while the future still has no listener.
      final expectation = expectLater(future, throwsA('conversion failed'));

      await sendPlatformCall('onHtmlError', <String, dynamic>{
        'job': job,
        'error': 'conversion failed',
      });

      await expectation;
    });
  });

  group('MethodChannelPrinting.raster', () {
    test('should emit the pages delivered by onPageRasterized', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final stream = platform.raster(
        Uint8List.fromList(<int>[1, 2, 3]),
        <int>[0],
        72,
      );

      // Subscribe before delivering events: `onPageRasterEnd` awaits
      // StreamController.close(), which only completes once the stream is
      // being listened to.
      final pagesFuture = stream.toList();

      await pumpEventQueue();
      final call = outgoing['rasterPdf']!;
      expect(call.arguments['pages'], <int>[0]);
      expect(call.arguments['scale'], closeTo(72 / PdfPageFormat.inch, 0.001));
      final int job = call.arguments['job'];

      await sendPlatformCall('onPageRasterized', <String, dynamic>{
        'job': job,
        'width': 10,
        'height': 20,
        'image': Uint8List.fromList(List<int>.filled(10 * 20 * 4, 0)),
      });
      await sendPlatformCall('onPageRasterEnd', <String, dynamic>{
        'job': job,
      });

      final pages = await pagesFuture;
      expect(pages.length, 1);
      expect(pages.first.width, 10);
      expect(pages.first.height, 20);
    });

    test('should surface the error delivered by onPageRasterEnd', () async {
      final MethodChannelPrinting platform = MethodChannelPrinting();

      final stream = platform.raster(
        Uint8List.fromList(<int>[1]),
        null,
        72,
      );

      // Subscribe before delivering the terminal event, and attach the
      // expectation up front so the stream error always has a listener.
      final expectation =
          expectLater(stream.toList(), throwsA('raster engine crashed'));

      await pumpEventQueue();
      final int job = outgoing['rasterPdf']!.arguments['job'];

      await sendPlatformCall('onPageRasterEnd', <String, dynamic>{
        'job': job,
        'error': 'raster engine crashed',
      });

      await expectation;
    });
  });
}
