import 'package:flutter_test/flutter_test.dart';
import 'package:maathai_llamma/maathai_llamma.dart';
import 'package:maathai_llamma/maathai_llamma_platform_interface.dart';
import 'package:maathai_llamma/maathai_llamma_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMaathaiLlammaPlatform
    with MockPlatformInterfaceMixin
    implements MaathaiLlammaPlatform {

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> loadModel({
    required String modelPath,
    int contextLength = 4096,
    int threads = 0,
    int gpuLayers = 0,
  }) async => modelPath.isNotEmpty;

  @override
  Future<String> generate({
    required String prompt,
    int maxTokens = 128,
  }) async => 'echo: $prompt (maxTokens=$maxTokens)';

  @override
  Future<void> release() async {}
}

void main() {
  final MaathaiLlammaPlatform initialPlatform = MaathaiLlammaPlatform.instance;

  test('$MethodChannelMaathaiLlamma is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMaathaiLlamma>());
  });

  test('initialize', () async {
    final plugin = MaathaiLlamma();
    final fakePlatform = MockMaathaiLlammaPlatform();
    MaathaiLlammaPlatform.instance = fakePlatform;

    expect(await plugin.initialize(), true);
  });

  test('loadModel', () async {
    final plugin = MaathaiLlamma();
    final fakePlatform = MockMaathaiLlammaPlatform();
    MaathaiLlammaPlatform.instance = fakePlatform;

    expect(await plugin.loadModel(modelPath: 'model.gguf'), true);
    expect(await plugin.loadModel(modelPath: ''), false);
  });

  test('generate', () async {
    final plugin = MaathaiLlamma();
    final fakePlatform = MockMaathaiLlammaPlatform();
    MaathaiLlammaPlatform.instance = fakePlatform;

    expect(
      await plugin.generate(prompt: 'Hello', maxTokens: 64),
      'echo: Hello (maxTokens=64)',
    );
  });
}
