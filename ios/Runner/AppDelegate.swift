import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Method Channel はエンジン初期化時に登録（window がまだ nil のことがあるため）
    let registrar = engineBridge.applicationRegistrar
    let channel = FlutterMethodChannel(
      name: "fitness_log_app/timer_live_activity",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler(TimerLiveActivityBridge.handle)
  }
}
