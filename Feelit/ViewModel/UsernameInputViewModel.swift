import Foundation

// MARK: - UsernameInputViewModel
/// Logic cho `UsernameInputViewController` (flow Welcome): validate username (3–16 ký tự) + lưu.
/// KHÔNG import UIKit.
final class UsernameInputViewModel {

    let minLen = 3
    let maxLen = 16

    private let usernameKey = "feelit_username"

    func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isValid(_ s: String) -> Bool {
        (minLen...maxLen).contains(trimmed(s).count)
    }

    /// Thông báo lỗi (tiếng Anh theo thiết kế màn này); `nil` nếu hợp lệ / rỗng.
    func errorMessage(for s: String) -> String? {
        let n = trimmed(s).count
        if n == 0 { return nil }
        if n < minLen { return "The username should not be less than \(minLen) characters" }
        if n > maxLen { return "The username should not be more than \(maxLen) characters" }
        return nil
    }

    func save(_ s: String) {
        UserDefaults.standard.set(trimmed(s), forKey: usernameKey)
    }
}
