import ActivityKit
import Flutter
import Foundation

/// Flutter の Method Channel から Live Activity を開始・終了するブリッジ。
/// iOS 16.1 以上で動作。Info.plist に NSSupportsLiveActivities = YES が必要。
final class TimerLiveActivityBridge {
    static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            guard let args = call.arguments as? [String: Any],
                  let initialSeconds = args["initialSeconds"] as? Int,
                  let endTimeEpochMs = args["endTimeEpochMs"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "initialSeconds and endTimeEpochMs required", details: nil))
                return
            }
            let endTime = Date(timeIntervalSince1970: Double(endTimeEpochMs) / 1000.0)
            if #available(iOS 16.2, *) {
                startLiveActivity(endTime: endTime)
            }
            result(nil)

        case "end":
            if #available(iOS 16.2, *) {
                endLiveActivity()
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @available(iOS 16.2, *)
    private static func startLiveActivity(endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TimerLiveActivityAttributes(endTime: endTime)
        let contentState = TimerLiveActivityAttributes.ContentState()
        let content = ActivityContent(state: contentState, staleDate: endTime)
        do {
            try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            #if DEBUG
            print("TimerLiveActivityBridge: start failed \(error)")
            #endif
        }
    }

    @available(iOS 16.2, *)
    private static func endLiveActivity() {
        for activity in Activity<TimerLiveActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
