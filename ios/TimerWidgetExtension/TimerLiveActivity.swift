import ActivityKit
import WidgetKit
import SwiftUI

/// ロック画面・Dynamic Island に表示するタイマー Live Activity。
/// Xcode で Widget Extension ターゲットを作成したあと、このファイルを Extension に追加し、
/// Runner の TimerLiveActivityAttributes.swift を Extension ターゲットのメンバーに追加すること。
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            // ロック画面
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.attributes.endTime, style: .timer)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.endTime, style: .timer)
                        .font(.title2.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.orange)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.attributes.endTime, style: .timer)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
