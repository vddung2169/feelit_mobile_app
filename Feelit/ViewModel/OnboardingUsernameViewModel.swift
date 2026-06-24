import Foundation

// MARK: - OnboardingUsernameViewModel
/// Logic cho `OnboardingUsernameViewController`: validate username + lưu vào UserDefaults.
/// KHÔNG import UIKit. Quy tắc: 3–16 ký tự, chỉ chữ cái / số / "." / "_".
final class OnboardingUsernameViewModel {

    let minLen = 3
    let maxLen = 16
    let charRule = "chỉ gồm chữ cái, số, dấu chấm (.) hoặc dấu gạch dưới (_)."

    private let usernameKey = "feelit_username"

    func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func hasValidChars(_ s: String) -> Bool {
        trimmed(s).range(of: #"^[A-Za-z0-9._]+$"#, options: .regularExpression) != nil
    }

    func isValid(_ s: String) -> Bool {
        let t = trimmed(s)
        return (minLen...maxLen).contains(t.count) && hasValidChars(s)
    }

    /// Thông báo lỗi để hiển thị; `nil` nếu hợp lệ hoặc đang rỗng (chưa cần báo).
    func errorMessage(for s: String) -> String? {
        let n = trimmed(s).count
        if n == 0 { return nil }
        if n < minLen { return "Tên người dùng không được ngắn hơn \(minLen) ký tự\n\(charRule)" }
        if n > maxLen { return "Tên người dùng không được dài quá \(maxLen) ký tự\n\(charRule)" }
        if !hasValidChars(s) { return "Tên người dùng \(charRule)" }
        return nil
    }

    func save(_ s: String) {
        UserDefaults.standard.set(trimmed(s), forKey: usernameKey)
    }
}
