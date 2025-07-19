/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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

import {
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

import { common } from '@kit.AbilityKit';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import PrintingJob from './PrintingJob'

const TAG = 'Printing';

/** PrintingPlugin **/
export default class PrintingPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  constructor() {
  }

  getUniqueClassName(): string {
    return "PrintingPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "net.nfet.printing");
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext() as common.UIAbilityContext;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "printPdf") {
      let name: string = call.argument('name');
      let width: number = call.argument('width');
      let height: number = call.argument('height');
      let marginLeft: number = call.argument('marginLeft');
      let marginTop: number = call.argument('marginTop');
      let marginRight: number = call.argument('marginRight');
      let marginBottom: number = call.argument('marginBottom');
      let job: number = call.argument('job');

      let printJob = new PrintingJob(this, job);
      printJob.printPdf(name, printJob, width, height, marginLeft, marginTop, marginRight, marginBottom);

      result.success(1);
    } else if (call.method == "cancelJob") {
      let job: number = call.argument('job');
      let printJob = new PrintingJob(this, job);
      printJob.cancelJob(null);

      result.success(1);
    } else if (call.method == "sharePdf") {
      let doc: Uint8Array = call.argument("doc");
      let name: string = call.argument("name");
      let subject: string = call.argument("subject");
      let body: string = call.argument("body");
      let emails: string[] = call.argument("emails");

      PrintingJob.sharePdf(getContext(this), doc, name, subject, body, emails);

      result.success(1);
    } else if (call.method == "convertHtml") {
      result.error('-1', 'This method is not supported. Please use another method to create your PDF document', null);
    } else if (call.method == "printingInfo") {
      result.success(PrintingJob.printingInfo());
    } else if (call.method == "rasterPdf") {
      let doc: Uint8Array = call.argument("doc");
      let pages: number[] = call.argument("pages");
      let scale: number = call.argument("scale");
      let job: number = call.argument("job");

      let printJob = new PrintingJob(this, job);
      printJob.rasterPdf(doc, pages, scale);

      result.success(1);
    } else {
      result.notImplemented();
    }
  }

  onPageRasterized(printJob: PrintingJob, imageData: Uint8Array, width: number, height: number): void {
    let data: Map<String, Object> = new Map();
    data.set('image', imageData);
    data.set('width', width);
    data.set('height', height);
    data.set('job', printJob.index);

    this.channel?.invokeMethod("onPageRasterized", data);
  }

  onPageRasterEnd(printJob: PrintingJob, error: string | null): void {
    let data: Map<String, Object> = new Map();
    data.set('job', printJob.index);
    if (error != null) {
      data.set('error', error);
    }

    this.channel?.invokeMethod("onPageRasterEnd", data);
  }

  // 从 Layout 获取打印数据
  public onLayout(printJob: PrintingJob, width: number, height: number, marginLeft: number, marginTop: number,
    marginRight: number, marginBottom: number) {
    let args: Map<string, Any> = new Map();
    args.set("width", width);
    args.set("height", height);
    args.set("marginLeft", marginLeft);
    args.set("marginTop", marginTop);
    args.set("marginRight", marginRight);
    args.set("marginBottom", marginBottom);
    args.set("job", printJob.index);

    const callback: MethodResult = {
      success: (result: Any) => {
        if (result instanceof Uint8Array) {
          if (this.context) {
            printJob.setDocument(result, this.context);
          } else {
            printJob.cancelJob("Context is not available");
          }
        } else {
          printJob.cancelJob("Unknown data received");
        }
      },
      error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
        printJob.cancelJob("Unknown data received");
        Log.e(TAG, 'Failed to get pdf data, error: ' + JSON.stringify(errorDetails));
      },
      notImplemented: (): void => {
        throw new Error('Function not implemented.');
      }
    }

    this.channel?.invokeMethod("onLayout", args, callback);
  }

  onCompleted(printJob: PrintingJob, completed: boolean, error: string | null) {
    let args: Map<string, Any> = new Map();
    args.set("completed", completed);
    args.set("error", error == null ? '' : error);
    args.set("job", printJob.index);
    this.channel?.invokeMethod("onCompleted", args);
  }
}