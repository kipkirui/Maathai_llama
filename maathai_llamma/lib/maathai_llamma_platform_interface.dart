import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'maathai_llamma_method_channel.dart';

abstract class MaathaiLlammaPlatform extends PlatformInterface {
  /// Constructs a MaathaiLlammaPlatform.
  MaathaiLlammaPlatform() : super(token: _token);

  static final Object _token = Object();

  static MaathaiLlammaPlatform _instance = MethodChannelMaathaiLlamma();

  /// The default instance of [MaathaiLlammaPlatform] to use.
  ///
  /// Defaults to [MethodChannelMaathaiLlamma].
  static MaathaiLlammaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MaathaiLlammaPlatform] when
  /// they register themselves.
  static set instance(MaathaiLlammaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

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
    int? mirostatType, // 0=off,1=mirostat,2=mirostat_v2
    double? mirostatTau,
    double? mirostatEta,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    int? repeatLastN,
    int? minKeep,
  }) {
    throw UnimplementedError('loadModel() has not been implemented.');
  }

  Future<String> generate({
    required String prompt,
    int maxTokens = 128,
    String? cancelToken,
  }) {
    throw UnimplementedError('generate() has not been implemented.');
  }

  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 128,
    String? cancelToken,
  }) {
    throw UnimplementedError('generateStream() has not been implemented.');
  }

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
  }) {
    throw UnimplementedError('updateSampler() has not been implemented.');
  }

  Future<void> cancel() {
    throw UnimplementedError('cancel() has not been implemented.');
  }

  Future<void> release() {
    throw UnimplementedError('release() has not been implemented.');
  }
}
