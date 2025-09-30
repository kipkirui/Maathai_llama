import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'maathai_llamma_platform_interface.dart';

/// An implementation of [MaathaiLlammaPlatform] that uses method channels.
class MethodChannelMaathaiLlamma extends MaathaiLlammaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('maathai_llamma');
  @visibleForTesting
  final eventsChannel = const EventChannel('maathai_llamma/events');

  @override
  Future<bool> initialize() async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] initialize()');
    }
    final initialized = await methodChannel.invokeMethod<bool>('initialize');
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] initialize -> ${initialized ?? false}');
    }
    return initialized ?? false;
  }

  @override
  Future<bool> loadModel({
    required String modelPath,
    int contextLength = 4096,
    int threads = 0,
    int? threadsBatch,
    int? batchSize,
    int gpuLayers = 0,
    bool preferPerformanceCores = true,
    int? maxModelBytes,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    double? minP,
    double? typicalP,
    double? topNSigma,
    int? mirostatType,
    double? mirostatTau,
    double? mirostatEta,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    int? repeatLastN,
    int? minKeep,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] loadModel(path=$modelPath, ctx=$contextLength, threads=$threads, threadsBatch=${threadsBatch ?? 0}, batchSize=${batchSize ?? 0}, gpuLayers=$gpuLayers, preferPerformanceCores=$preferPerformanceCores, maxModelBytes=${maxModelBytes ?? -1})');
    }
    final loaded = await methodChannel.invokeMethod<bool>('loadModel', {
      'modelPath': modelPath,
      'contextLength': contextLength,
      'threads': threads,
      'threadsBatch': threadsBatch,
      'batchSize': batchSize,
      'gpuLayers': gpuLayers,
      'preferPerformanceCores': preferPerformanceCores,
      'maxModelBytes': maxModelBytes,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
      'topNSigma': topNSigma,
      'mirostatType': mirostatType,
      'mirostatTau': mirostatTau,
      'mirostatEta': mirostatEta,
      'repeatPenalty': repeatPenalty,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'repeatLastN': repeatLastN,
      'minKeep': minKeep,
    });
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] loadModel -> ${loaded ?? false}');
    }
    return loaded ?? false;
  }

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 128,
    String? cancelToken,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] generate(maxTokens=$maxTokens) prompt="${prompt.substring(0, prompt.length > 64 ? 64 : prompt.length)}"');
    }
    final response = await methodChannel.invokeMethod<String>('generate', {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'cancelToken': cancelToken,
    });
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] generate -> len=${response?.length ?? 0}');
    }
    return response ?? '';
  }

  @override
  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 128,
    String? cancelToken,
  }) {
    final controller = StreamController<String>();
    // Subscribe first so native onListen gets called and eventSink is available
    final sub = eventsChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event['type'];
        if (type == 'token') {
          final text = (event['text'] as String?) ?? '';
          if (text.isNotEmpty && !controller.isClosed) controller.add(text);
        } else if (type == 'done') {
          if (kDebugMode) {
            // ignore: avoid_print
            print('[MaathaiLlamma] stream done');
          }
          if (!controller.isClosed) controller.close();
        }
      }
    }, onError: (error, stack) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[MaathaiLlamma] stream error: $error');
      }
      if (!controller.isClosed) controller.addError(error, stack);
    });

    () async {
      try {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[MaathaiLlamma] startGenerateStream(maxTokens=$maxTokens)');
        }
        final started = await methodChannel.invokeMethod<bool>('startGenerateStream', {
          'prompt': prompt,
          'maxTokens': maxTokens,
          'cancelToken': cancelToken,
        });
        if (started != true) {
          throw PlatformException(code: 'start_failed', message: 'Failed to start generation stream');
        }
      } catch (e, st) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[MaathaiLlamma] startGenerateStream error: $e');
        }
        if (!controller.isClosed) controller.addError(e, st);
      }
    }();

    controller.onCancel = () async {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[MaathaiLlamma] cancelGenerate');
      }
      await methodChannel.invokeMethod('cancelGenerate');
      await sub.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> updateSampler({
    required double temperature,
    required int topK,
    required double topP,
    double? minP,
    double? typicalP,
    double? topNSigma,
    int? mirostatType,
    double? mirostatTau,
    double? mirostatEta,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    int? repeatLastN,
    int? minKeep,
  }) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] updateSampler');
    }
    await methodChannel.invokeMethod('updateSampler', {
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
      'topNSigma': topNSigma,
      'mirostatType': mirostatType,
      'mirostatTau': mirostatTau,
      'mirostatEta': mirostatEta,
      'repeatPenalty': repeatPenalty,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,
      'repeatLastN': repeatLastN,
      'minKeep': minKeep,
    });
  }

  @override
  Future<void> cancel() async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] cancel()');
    }
    await methodChannel.invokeMethod('cancelGenerate');
  }

  @override
  Future<void> release() async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[MaathaiLlamma] release()');
    }
    await methodChannel.invokeMethod<void>('release');
  }
}
