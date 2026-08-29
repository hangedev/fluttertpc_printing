# ChangeLog

## 5.14.2-ohos-1.0.1 - 2026.9

### Added
* Implement `AbilityAware` in `PrintingPlugin` to hold the UIAbility reference and release print jobs when the ability detaches.
* Add unit tests covering printing APIs, preview widgets, fonts, caches, rasterization, and `WidgetWrapper`.
* Add platform-implementation mock tests for `MethodChannelPrinting`/`PrintingPlatform` (all seven methods, job lifecycle callbacks), pure Dart logic tests (`Mutex`, `PrintJobs`, `PdfBaseCache`, `AssetManifest`), exception-scenario tests (printer offline/unavailable, timeouts, permission denials), FFI side-channel tests, and representative parameterized `PdfGoogleFonts` loader tests.

### Fixed
* Track active print jobs in `PrintingPlugin` so `cancelJob` cancels the original job instance instead of a newly created one.
* Deduplicate `onCompleted` events per job to prevent double completion errors on the Flutter side.
* Cancel all active print jobs and clear the MethodChannel handler on engine or ability detach to release resources and notify Flutter of the cancellation.
* Handle Promise rejections of `invokeMethod` calls for `onPageRasterized`, `onPageRasterEnd`, and `onCompleted` to avoid unhandled rejections and hung Flutter streams.
* Cancel the job instead of throwing when the `onLayout` callback is not implemented, and guard the invocation with try-catch to prevent crashes and indefinite waits.
* Wrap `onMethodCall` in a global try-catch so unexpected native exceptions are returned to Flutter instead of crashing the app.
* Validate arguments of `printPdf`, `cancelJob`, `sharePdf`, and `rasterPdf`, and reject invalid input with an error result.
* Cancel the previous active job when `printPdf` or `rasterPdf` is invoked again with the same job index.
* Fix `rasterPdf` to rasterize the requested page numbers instead of sequential indices when `pages` is provided, and skip out-of-range page indices.
* Signal `onPageRasterEnd` on empty data, invalid scale, PDF load failure, or exceptions in `rasterPdf` so the Flutter stream always closes.
* Release PixelMap and PdfDocument native resources in try-finally blocks in `rasterPdf` to fix per-page memory leaks.
* Close file descriptors in try-finally when writing temporary PDF files in `rasterPdf`, `sharePdf`, and `setDocument`.
* Delete temporary PDF files after printing, sharing, and rasterization to prevent unbounded temp directory growth.
* Report job failure instead of leaving the job hanging when `onStartLayoutWrite` or `print.print` fails in `setDocument`.
* Release the print adapter reference on job completion or cancellation to break circular references and allow garbage collection.
* Guard the `onJobStateChanged` callback with try-catch so system print service callbacks cannot crash the app.
* Report the post-scale raster dimensions (`width*scale × height*scale`) in `onPageRasterized` so the Dart side `PdfRaster.toImage()` decodes without distortion.
* Derive `PrintAttributes` page size from the document layout dimensions (matching the nearest predefined paper type within ±20 mils, falling back to a custom `PrintPageSize`) instead of hardcoding A3/monochrome/page range.
* Return `dynamicLayout: false` from `printingInfo` to reflect that the OHOS print adapter does not re-trigger `onLayout` when the user changes print settings.

### Changed
* Use distinct MethodChannel error codes (`invalid_arguments`, `not_supported`, `internal_error`) instead of the hardcoded `'-1'`.

## 5.14.2-ohos-1.0.0
- feat: Support Flutter OHOS 3.35.7.
