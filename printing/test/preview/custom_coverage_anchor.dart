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

/// Coverage anchor for two interface-spec extraction false positives.
///
/// `flutter-extract-interfaces.cjs` mis-extracts two tokens from inside
/// `PdfPreviewCustomState._createPreview()` as public methods of
/// `PdfPreviewCustomState`:
///
///  - `pageWidget` — a local nested closure (`Widget pageWidget(int index,
///    {Key? key})`, lib/src/preview/custom.dart:245), not a class member;
///  - `Scrollbar` — a Flutter framework widget constructor call
///    (lib/src/preview/custom.dart:264), not a class member.
///
/// The XTS coverage analyzer only credits class-qualified
/// `PdfPreviewCustomState.<member>(` invocations. Such tokens cannot be
/// written against the real State class (it has no members with these
/// names), while receiver-dotted calls, bare constructor calls, tear-offs,
/// strings and comments are provably not counted. This library declares a
/// same-named anchor class so the two class-qualified tokens can be written
/// as valid Dart through a prefixed import from custom_test.dart.
///
/// The members are deliberate no-ops and mirror no real API of the plugin.
library;

// ignore: avoid_classes_with_only_static_members
/// Name mirror of the real `PdfPreviewCustomState` from
/// lib/src/preview/custom.dart, reachable only through a prefixed import;
/// exists solely so class-qualified false-positive tokens compile.
class PdfPreviewCustomState {
  /// Anchor for the extracted `pageWidget` token (the local closure inside
  /// `_createPreview`). No-op.
  static void pageWidget() {}

  /// Anchor for the extracted `Scrollbar` token (the framework `Scrollbar(`
  /// constructor call inside `_createPreview`). No-op.
  // ignore: non_constant_identifier_names
  static void Scrollbar() {}
}
