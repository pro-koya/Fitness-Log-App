import Flutter
import UIKit
import StoreKit

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
    let purchaseChannel = FlutterMethodChannel(
      name: "fitness_log_app/purchase_environment",
      binaryMessenger: registrar.messenger()
    )
    purchaseChannel.setMethodCallHandler { call, result in
      guard call.method == "getEnvironment" else { result(FlutterMethodNotImplemented); return }
      Task { @MainActor in result(await Self.purchaseEnvironment()) }
    }
  }
  private static func purchaseEnvironment() async -> String? {
    if #available(iOS 16.0, *) {
      do {
        let verification = try await AppTransaction.shared
        guard case .verified(let transaction) = verification else { return nil }
        switch transaction.environment {
        case .production: return "Production"
        case .sandbox: return "Sandbox"
        default: return nil
        }
      } catch {
        // Retry on the next foreground refresh, purchase or restore; no forced sign-in prompt.
      }
    }
    guard let receipt = Bundle.main.appStoreReceiptURL,
          FileManager.default.fileExists(atPath: receipt.path) else { return nil }
    switch receipt.lastPathComponent {
    case "sandboxReceipt": return "Sandbox"
    case "receipt": return "Production"
    default: return nil
    }
  }
}
