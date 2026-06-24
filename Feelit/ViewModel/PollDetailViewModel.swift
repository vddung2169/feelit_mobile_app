import CoreGraphics

// MARK: - PollDetailViewModel
/// Logic cho `PollDetailViewController`: giữ `item`, văn bản quy tắc, và dữ liệu sóng cho biểu đồ.
/// KHÔNG import UIKit.
final class PollDetailViewModel {

    let item: PollCardItem

    let rulesText = "Resolves Yes if the simple average of the sixty seconds of CF Benchmarks' Bitcoin Real-Time Index (BRTI) before 5 AM EDT is above 62599.99 at 5 AM EDT on Jun 19, 2026. Outcome verified from CF Benchmarks.\n\nNot all cryptocurrency price data is the same. While checking a source like Google or Coinbase may help guide your decision, the price used to determine this market is based on CF Benchmarks' corresponding Real Time Index (RTI). At the last minute before expiration, 60 RTI prices are collected. The official and final value is the average of these prices.\n\nNote: this event is directional."
    let insiderText = "The following are prohibited from trading this contract: Persons who are employed by any of the Source Agencies are not permitted to trade on the Contract.\n\nPersons who hold any material, non-public information on the Underlying are not permitted to trade on the Contract."

    init(item: PollCardItem) {
        self.item = item
    }

    /// Chuỗi % "CÓ" (xanh) cho biểu đồ — dữ liệu giả lập.
    var yesSeries: [CGFloat] { Self.wave(count: 24, base: 0.55, amp: 0.18, up: 0.15) }
    /// Chuỗi % "KHÔNG" (đỏ).
    var noSeries: [CGFloat] { Self.wave(count: 24, base: 0.45, amp: 0.16, up: -0.12) }

    /// Sinh dữ liệu sóng giả lập 0...1.
    private static func wave(count: Int, base: CGFloat, amp: CGFloat, up: CGFloat) -> [CGFloat] {
        (0..<count).map { i in
            let t = CGFloat(i) / CGFloat(count - 1)
            let s = sin(t * .pi * 3) * amp + sin(t * .pi * 7) * amp * 0.4
            return min(max(base + s + up * t, 0.05), 0.95)
        }
    }
}
