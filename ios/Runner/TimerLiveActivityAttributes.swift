import ActivityKit
import Foundation

/// Live Activity で表示するタイマー用の属性。
/// Runner と Widget Extension の両方のターゲットにこのファイルを追加すること。
@available(iOS 16.2, *)
public struct TimerLiveActivityAttributes: ActivityAttributes {
    public typealias ContentState = TimerContentState

    /// タイマー終了予定時刻（ロック画面で残り時間の計算に使用）
    public let endTime: Date

    public init(endTime: Date) {
        self.endTime = endTime
    }
}

public struct TimerContentState: Codable, Hashable {
    public init() {}
}
