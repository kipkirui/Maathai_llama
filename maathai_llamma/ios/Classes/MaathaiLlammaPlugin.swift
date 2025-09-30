import Flutter
import UIKit

public class MaathaiLlammaPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "maathai_llamma", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "maathai_llamma/events", binaryMessenger: registrar.messenger())
    let instance = MaathaiLlammaPlugin()

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      result(false)
    case "loadModel", "updateSampler", "startGenerateStream", "generate":
      result(FlutterError(code: "unimplemented", message: "maathai_llamma: iOS bindings are not available yet.", details: nil))
    case "cancelGenerate", "release":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return FlutterError(code: "unimplemented", message: "maathai_llamma streaming is not available on iOS yet.", details: nil)
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
