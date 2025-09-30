import 'package:flutter/foundation.dart';
import 'package:maathai_llamma/maathai_llamma.dart';
import '../services/model_service.dart';
import '../utils/logger.dart';

class ModelController extends ChangeNotifier {
  final MaathaiLlamma _client = MaathaiLlamma();

  bool _backendReady = false;
  bool _modelLoaded = false;
  ModelInfo? _activeModel;
  int _contextLength = 4096;
  int _threads = 0;
  int _gpuLayers = 0;
  // UI / thinking settings
  bool _showThinkingIndicator = true;
  bool _captureThinking = true;
  // sampler params
  double temperature = 0.7;
  int topK = 40;
  double topP = 0.95;
  double? minP;
  double? typicalP;
  double? topNSigma;
  int mirostatType = 0;
  double? mirostatTau;
  double? mirostatEta;
  double? repeatPenalty;
  double? frequencyPenalty;
  double? presencePenalty;
  int? repeatLastN;
  int? minKeep;

  bool get backendReady => _backendReady;
  bool get modelLoaded => _modelLoaded;
  ModelInfo? get activeModel => _activeModel;
  int get contextLength => _contextLength;
  int get threads => _threads;
  int get gpuLayers => _gpuLayers;
  bool get showThinkingIndicator => _showThinkingIndicator;
  bool get captureThinking => _captureThinking;

  // runtime tuning setters
  void setThreads(int value) {
    _threads = value;
    notifyListeners();
  }

  void setGpuLayers(int value) {
    _gpuLayers = value;
    notifyListeners();
  }

  void setContextLength(int value) {
    _contextLength = value;
    notifyListeners();
  }

  void setShowThinkingIndicator(bool value) {
    _showThinkingIndicator = value;
    notifyListeners();
  }

  void setCaptureThinking(bool value) {
    _captureThinking = value;
    notifyListeners();
  }

  Future<bool> initializeBackend() async {
    try {
      _backendReady = await _client.initialize();
      Logger.info('Backend initialized', data: {'ready': _backendReady});
    } catch (e) {
      _backendReady = false;
      Logger.error('Backend initialization failed', data: e);
    }
    notifyListeners();
    return _backendReady;
  }

  Future<bool> loadModel(ModelInfo model, {int? contextLength, int? threads, int? gpuLayers}) async {
    if (!_backendReady) {
      await initializeBackend();
      if (!_backendReady) return false;
    }
    _contextLength = contextLength ?? _contextLength;
    _threads = threads ?? _threads;
    _gpuLayers = gpuLayers ?? _gpuLayers;

    try {
      final ok = await _client.loadModel(
        modelPath: model.path,
        contextLength: _contextLength,
        threads: _threads,
        gpuLayers: _gpuLayers,
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
      _modelLoaded = ok;
      _activeModel = ok ? model : null;
      Logger.info('Model load result', data: {
        'ok': ok,
        'path': model.path,
        'ctx': _contextLength,
        'threads': _threads,
        'gpuLayers': _gpuLayers,
      });
      notifyListeners();
      return ok;
    } catch (e) {
      _modelLoaded = false;
      _activeModel = null;
      Logger.error('Failed to load model', data: e);
      notifyListeners();
      return false;
    }
  }

  Future<String> generate(String prompt, {int maxTokens = 512}) async {
    try {
      Logger.info('Generate request', data: {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'model': _activeModel?.name,
      });
      final response = await _client.generate(prompt: prompt, maxTokens: maxTokens);
      Logger.success('Generate response OK');
      return response;
    } catch (e) {
      Logger.error('Generate failed', data: e);
      rethrow;
    }
  }

  Stream<String> generateStream(String prompt, {int maxTokens = 512}) {
    Logger.info('GenerateStream request', data: {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'model': _activeModel?.name,
    });
    int emitted = 0;
    return _client.generateStream(prompt: prompt, maxTokens: maxTokens).map((chunk) {
      emitted += 1;
      if (emitted % 8 == 0) {
        Logger.info('GenerateStream progress', data: {'tokens': emitted});
      }
      return chunk;
    });
  }

  Future<void> updateSamplerParams({
    double? temperature,
    int? topK,
    double? topP,
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
    if (temperature != null) this.temperature = temperature;
    if (topK != null) this.topK = topK;
    if (topP != null) this.topP = topP;
    if (minP != null) this.minP = minP;
    if (typicalP != null) this.typicalP = typicalP;
    if (topNSigma != null) this.topNSigma = topNSigma;
    if (mirostatType != null) this.mirostatType = mirostatType;
    if (mirostatTau != null) this.mirostatTau = mirostatTau;
    if (mirostatEta != null) this.mirostatEta = mirostatEta;
    if (repeatPenalty != null) this.repeatPenalty = repeatPenalty;
    if (frequencyPenalty != null) this.frequencyPenalty = frequencyPenalty;
    if (presencePenalty != null) this.presencePenalty = presencePenalty;
    if (repeatLastN != null) this.repeatLastN = repeatLastN;
    if (minKeep != null) this.minKeep = minKeep;

    await _client.updateSampler(
      temperature: this.temperature,
      topK: this.topK,
      topP: this.topP,
      minP: this.minP,
      typicalP: this.typicalP,
      topNSigma: this.topNSigma,
      mirostatType: this.mirostatType,
      mirostatTau: this.mirostatTau,
      mirostatEta: this.mirostatEta,
      repeatPenalty: this.repeatPenalty,
      frequencyPenalty: this.frequencyPenalty,
      presencePenalty: this.presencePenalty,
      repeatLastN: this.repeatLastN,
      minKeep: this.minKeep,
    );
    notifyListeners();
  }

  Future<void> cancel() => _client.cancel();

  Future<void> release() async {
    try {
      await _client.release();
    } catch (_) {}
    _modelLoaded = false;
    _activeModel = null;
    notifyListeners();
  }
}


