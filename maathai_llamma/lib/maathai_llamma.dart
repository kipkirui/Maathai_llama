
import 'maathai_llamma_platform_interface.dart';

class MaathaiLlamma {
  Future<bool> initialize() => MaathaiLlammaPlatform.instance.initialize();

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
  }) {
    return MaathaiLlammaPlatform.instance.loadModel(
      modelPath: modelPath,
      contextLength: contextLength,
      threads: threads,
      threadsBatch: threadsBatch,
      batchSize: batchSize,
      gpuLayers: gpuLayers,
      preferPerformanceCores: preferPerformanceCores,
      maxModelBytes: maxModelBytes,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      topNSigma: topNSigma,
      mirostatType: mirostatType,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      repeatPenalty: repeatPenalty,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      repeatLastN: repeatLastN,
      minKeep: minKeep,
    );
  }

  Future<String> generate({
    required String prompt,
    int maxTokens = 512,
    String? cancelToken,
  }) {
    return MaathaiLlammaPlatform.instance.generate(
      prompt: prompt,
      maxTokens: maxTokens,
      cancelToken: cancelToken,
    );
  }

  Stream<String> generateStream({
    required String prompt,
    int maxTokens = 512,
    String? cancelToken,
  }) {
    return MaathaiLlammaPlatform.instance.generateStream(
      prompt: prompt,
      maxTokens: maxTokens,
      cancelToken: cancelToken,
    );
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
    return MaathaiLlammaPlatform.instance.updateSampler(
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      topNSigma: topNSigma,
      mirostatType: mirostatType,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      repeatPenalty: repeatPenalty,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      repeatLastN: repeatLastN,
      minKeep: minKeep,
    );
  }

  Future<void> cancel() {
    return MaathaiLlammaPlatform.instance.cancel();
  }

  Future<void> release() => MaathaiLlammaPlatform.instance.release();
}
