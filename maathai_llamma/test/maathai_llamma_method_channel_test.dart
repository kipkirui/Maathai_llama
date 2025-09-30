import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maathai_llamma/maathai_llamma_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelMaathaiLlamma();
  const MethodChannel channel = MethodChannel('maathai_llamma');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'initialize':
            return true;
          case 'loadModel':
            return true;
          case 'generate':
            return 'native-response';
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('generate delegates to native channel', () async {
    final result = await platform.generate(prompt: 'Hi there', maxTokens: 32);
    expect(result, 'native-response');
  });

  test('loadModel delegates to native channel', () async {
    final ok = await platform.loadModel(modelPath: 'path/to/model');
    expect(ok, isTrue);
  });

  test('initialize delegates to native channel', () async {
    final ok = await platform.initialize();
    expect(ok, isTrue);
  });
}
