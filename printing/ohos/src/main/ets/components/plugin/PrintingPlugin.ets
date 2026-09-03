// Copyright (c) 2025 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on Camera.java originally written by
// Copyright 2013 The Flutter Authors.

import {
  AbilityAware,
  AbilityPluginBinding,
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

import { UIAbility } from '@kit.AbilityKit';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import PrintingJob from './PrintingJob'

const TAG = 'Printing';

/** PrintingPlugin **/
export default class PrintingPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private channel: MethodChannel | null = null;
  // 跟踪活跃的打印任务，确保 cancelJob 能引用原始实例，避免多实例状态不一致
  private printJobs: Map<number, PrintingJob> = new Map();
  // 已完成任务的去重标记：onStartLayoutWrite 失败路径与 onJobStateChanged 终态回调都可能
  // 调用 onCompleted，系统打印服务回调线程未在文档中明确保证，去重可避免 Flutter 侧收到两次
  // onCompleted（Completer 二次 complete 报错）及对 printJobs 的并发修改
  private completedJobs: Set<number> = new Set();
  // 绑定的 UIAbility，用于打印/分享 API 所需的 context
  private ability: UIAbility | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return 'PrintingPlugin'
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'net.nfet.printing');
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // 引擎分离时清理所有活跃打印任务，释放资源并通知 Flutter 侧任务被取消
    this.printJobs.forEach((job: PrintingJob, key: number) => {
      job.cancelJob('Engine detached');
    });
    this.printJobs.clear();
    // 同步清理去重标记表，避免长期累积导致内存增长
    this.completedJobs.clear();

    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null;
    }
  }

  // Ability 生命周期绑定：Ability 附加时持有引用，用于打印/分享 API
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  // Ability 分离（如销毁、屏幕旋转重建）时清理所有打印任务并释放引用，避免回调指向无效上下文
  onDetachedFromAbility(): void {
    this.printJobs.forEach((job: PrintingJob, key: number) => {
      job.cancelJob('Ability detached');
    });
    this.printJobs.clear();
    this.completedJobs.clear();
    this.ability = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    // 关键路径全局异常保护：任何未捕获异常都通过 result.error 返回 Flutter 侧，避免应用崩溃
    try {
      if (call.method == 'printPdf') {
        let name: string = call.argument('name');
        let width: number = call.argument('width');
        let height: number = call.argument('height');
        let marginLeft: number = call.argument('marginLeft');
        let marginTop: number = call.argument('marginTop');
        let marginRight: number = call.argument('marginRight');
        let marginBottom: number = call.argument('marginBottom');
        let job: number = call.argument('job');
        // 参数验证：类型不匹配或关键参数缺失时拒绝执行
        if (typeof width !== 'number' || typeof height !== 'number' || typeof job !== 'number') {
          result.error('invalid_arguments', 'Invalid arguments for printPdf', null);
          return;
        }
        // name 必须为非空字符串
        if (typeof name !== 'string' || name.length === 0) {
          result.error('invalid_arguments', 'Invalid arguments for printPdf: name is required', null);
          return;
        }
        // margins 必须为非负数（负边距会导致打印布局异常），缺失时视为合法（null/undefined）
        if ((marginLeft != null && marginLeft < 0) || (marginTop != null && marginTop < 0) ||
          (marginRight != null && marginRight < 0) || (marginBottom != null && marginBottom < 0)) {
          result.error('invalid_arguments', 'Invalid arguments for printPdf: margins must be non-negative', null);
          return;
        }
        // 状态追踪：若该 job 已有活跃任务，先取消旧任务，避免重复注册打印 adapter
        let existingJob = this.printJobs.get(job);
        if (existingJob != null) {
          existingJob.cancelJob('Replaced by new printPdf');
        }
        // 清除旧任务遗留的去重标记，确保新任务能正常触发 onCompleted
        this.completedJobs.delete(job);

        let printJob = new PrintingJob(this, job);
        this.printJobs.set(job, printJob);
        printJob.printPdf(name, printJob, width, height, marginLeft, marginTop, marginRight, marginBottom);

        result.success(1);
      } else if (call.method == 'cancelJob') {
        let job: number = call.argument('job');
        if (typeof job !== 'number') {
          result.error('invalid_arguments', 'Invalid arguments for cancelJob', null);
          return;
        }
        // 引用原始实例进行取消，确保能取消真实任务
        let printJob = this.printJobs.get(job);
        if (printJob != null) {
          printJob.cancelJob(null);
          this.printJobs.delete(job);
          // 清除去重标记，允许同索引后续注册的新任务正常完成
          this.completedJobs.delete(job);
        } else {
          // 兜底：原始实例已被回收时也通知 Flutter 侧当前任务结束
          let fallbackJob = new PrintingJob(this, job);
          fallbackJob.cancelJob(null);
          this.completedJobs.delete(job);
        }

        result.success(1);
      } else if (call.method == 'sharePdf') {
        let doc: Uint8Array = call.argument('doc');
        let name: string = call.argument('name');
        let subject: string = call.argument('subject');
        let body: string = call.argument('body');
        let emails: string[] = call.argument('emails');
        if (!(doc instanceof Uint8Array) || name == null) {
          result.error('invalid_arguments', 'Invalid arguments for sharePdf', null);
          return;
        }

        PrintingJob.sharePdf(getContext(this), doc, name, subject, body, emails);

        result.success(1);
      } else if (call.method == 'convertHtml') {
        result.error('not_supported',
          'This method is not supported. Please use another method to create your PDF document', null);
      } else if (call.method == 'printingInfo') {
        result.success(PrintingJob.printingInfo());
      } else if (call.method == 'rasterPdf') {
        let doc: Uint8Array = call.argument('doc');
        let pages: number[] = call.argument('pages');
        let scale: number = call.argument('scale');
        let job: number = call.argument('job');
        if (!(doc instanceof Uint8Array) || typeof job !== 'number') {
          result.error('invalid_arguments', 'Invalid arguments for rasterPdf', null);
          return;
        }

        // 状态追踪：与 printPdf 一致，若该 job 已有活跃光栅化任务，先取消旧任务，
        // 避免旧任务的 onPageRasterEnd 误删新任务在跟踪表中的条目
        let existingRasterJob = this.printJobs.get(job);
        if (existingRasterJob != null) {
          existingRasterJob.cancelJob('Replaced by new rasterPdf');
        }
        // 清除旧任务遗留的去重标记，确保新任务能正常触发 onCompleted
        this.completedJobs.delete(job);

        let printJob = new PrintingJob(this, job);
        this.printJobs.set(job, printJob);
        printJob.rasterPdf(doc, pages, scale);

        result.success(1);
      } else {
        result.notImplemented();
      }
    } catch (e) {
      let msg = e instanceof Error ? e.message : JSON.stringify(e);
      Log.e(TAG, 'onMethodCall error (' + call.method + '): ' + msg);
      result.error('internal_error', 'Internal error: ' + msg, null);
    }
  }

  onPageRasterized(printJob: PrintingJob, imageData: Uint8Array, width: number, height: number): void {
    let data: Map<String, Object> = new Map();
    data.set('image', imageData);
    data.set('width', width);
    data.set('height', height);
    data.set('job', printJob.index);

    // 本版本 flutter_ohos 的 invokeMethod 返回 void（不传 MethodResult 时平台回复被忽略），
    // 无 Promise rejection 可处理；用 try/catch 捕获引擎分离等边界场景的同步异常，
    // 避免异常沿系统打印回调传播导致应用崩溃
    if (this.channel != null) {
      try {
        this.channel.invokeMethod('onPageRasterized', data);
      } catch (e) {
        Log.e(TAG, 'onPageRasterized invokeMethod error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
      }
    }
  }

  onPageRasterEnd(printJob: PrintingJob, error: string | null): void {
    let data: Map<String, Object> = new Map();
    data.set('job', printJob.index);
    if (error != null) {
      data.set('error', error);
    }

    // invokeMethod 返回 void，无异步 rejection；用 try/catch 捕获同步异常，避免异常
    // 沿系统打印回调传播导致应用崩溃
    if (this.channel != null) {
      try {
        this.channel.invokeMethod('onPageRasterEnd', data);
      } catch (e) {
        Log.e(TAG, 'onPageRasterEnd invokeMethod error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
      }
    }
    // 光栅化流结束后从跟踪表中移除，释放 PrintingJob 引用
    this.printJobs.delete(printJob.index);
  }

  // 从 Layout 获取打印数据
  // 数值类型说明：ArkTS StandardMessageCodec 按 Number.isInteger 判定，整型 number 一律
  // 编码为 int32/int64（width * 1.0 等乘法无法改变编码类型），Dart 侧 method_channel 已按
  // Platform.isOhos 分支做 int→double 转换，此处保持原值发送即可
  public onLayout(printJob: PrintingJob, width: number, height: number, marginLeft: number, marginTop: number,
    marginRight: number, marginBottom: number) {
    let args: Map<string, Any> = new Map();
    args.set('width', width);
    args.set('height', height);
    args.set('marginLeft', marginLeft);
    args.set('marginTop', marginTop);
    args.set('marginRight', marginRight);
    args.set('marginBottom', marginBottom);
    args.set('job', printJob.index);

    const callback: MethodResult = {
      success: (result: Any) => {
        if (result instanceof Uint8Array) {
          printJob.setDocument(result);
        } else {
          printJob.cancelJob('Unknown data received');
        }
      },
      error: (errorCode: string, errorMessage: string, errorDetails: Any) => {
        printJob.cancelJob('Unknown data received');
        Log.e(TAG, 'Failed to get pdf data, error: ' + JSON.stringify(errorDetails));
      },
      notImplemented: (): void => {
        // Flutter 未实现 onLayout 时不应抛异常（会导致应用崩溃），改为取消任务并通知 Flutter 侧
        Log.e(TAG, 'onLayout notImplemented callback invoked');
        printJob.cancelJob('onLayout not implemented');
      }
    }

    // invokeMethod 同步调用保护：引擎分离等边界场景下调用可能抛出，需捕获并取消任务，
    // 避免应用崩溃及 Flutter 侧等待布局回调超时。异步结果通过 callback 的 success/error/notImplemented
    // 三个分支回传，已分别处理正常数据、错误与未实现，无需额外 Promise 处理
    try {
      if (this.channel != null) {
        this.channel.invokeMethod('onLayout', args, callback);
      } else {
        // channel 已释放时直接取消任务，避免 Flutter 侧无限等待布局回调
        printJob.cancelJob('onLayout channel detached');
      }
    } catch (e) {
      Log.e(TAG, 'onLayout invokeMethod error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
      printJob.cancelJob('onLayout invokeMethod failed');
    }
  }

  onCompleted(printJob: PrintingJob, completed: boolean, error: string | null) {
    // 去重保护：onStartLayoutWrite 失败路径与 onJobStateChanged 终态回调都可能触发 onCompleted，
    // 系统回调线程未在文档中明确保证，首次完成后标记并直接返回，避免 Flutter 侧收到两次完成事件
    // （Completer 二次 complete 报错）及对 printJobs 的并发修改
    if (this.completedJobs.has(printJob.index)) {
      return;
    }
    this.completedJobs.add(printJob.index);

    let args: Map<string, Any> = new Map();
    args.set('completed', completed);
    args.set('error', error == null ? '' : error);
    args.set('job', printJob.index);
    // invokeMethod 返回 void，无异步 rejection；用 try/catch 捕获同步异常，避免异常
    // 沿系统打印回调传播导致应用崩溃
    if (this.channel != null) {
      try {
        this.channel.invokeMethod('onCompleted', args);
      } catch (e) {
        Log.e(TAG, 'onCompleted invokeMethod error: ' + (e instanceof Error ? e.message : JSON.stringify(e)));
      }
    }
    // 任务结束（成功/失败/取消）后从跟踪表中移除，释放 PrintingJob 及其闭包引用
    this.printJobs.delete(printJob.index);
    this.completedJobs.delete(printJob.index);
  }
}