import Foundation

/// Tạo và lưu UUID vĩnh viễn cho mỗi lần cài app.
/// Cùng device luôn dùng cùng 1 ID → server nhận diện được duplicate vote.
final class DeviceIdManager {

    static let shared = DeviceIdManager()
    private init() {}

    private let key = "poll_device_id"

    var deviceId: String {
        if let saved = UserDefaults.standard.string(forKey: key) {
            return saved
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}
