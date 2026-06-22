import Foundation
import Security

/// Lưu accessToken + refreshToken trong Keychain — an toàn hơn UserDefaults.
final class TokenStore {
    static let shared = TokenStore()
    private init() {}

    private let service = "vn.feelit.auth"

    private enum Key: String {
        case accessToken, refreshToken, userId
    }

    var accessToken: String? {
        get { read(.accessToken) }
        set { newValue == nil ? delete(.accessToken) : write(.accessToken, newValue!) }
    }

    var refreshToken: String? {
        get { read(.refreshToken) }
        set { newValue == nil ? delete(.refreshToken) : write(.refreshToken, newValue!) }
    }

    var currentUserId: String? {
        get { read(.userId) }
        set { newValue == nil ? delete(.userId) : write(.userId, newValue!) }
    }

    var isLoggedIn: Bool { accessToken != nil }

    func saveSession(_ session: AuthSessionResponse) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        currentUserId = session.user.id
    }

    func clearSession() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
    }

    // MARK: - Keychain primitives
    private func read(_ key: Key) -> String? {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var ref: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ref) == errSecSuccess,
              let data = ref as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ key: Key, _ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }

    private func delete(_ key: Key) {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        SecItemDelete(q as CFDictionary)
    }
}
