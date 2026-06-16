import Foundation

// MARK: - AppNotification
/// Thông báo từ server (vd poll kết thúc). Đặt tên AppNotification để khỏi đụng
/// Foundation.Notification. Keys server trả camelCase nên decode trực tiếp.
struct AppNotification: Codable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let body: String
    let data: NotificationData?
    let pollId: String?
    let isRead: Bool
    let createdAt: String

    /// pollId ưu tiên field top-level, fallback trong `data`.
    var resolvedPollId: String? { pollId ?? data?.pollId }

    var formattedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: createdAt) ?? ISO8601DateFormatter().date(from: createdAt)
        guard let date = date else { return "" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "vi_VN")
        out.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "dd/MM"
        return out.string(from: date)
    }
}

// MARK: - NotificationData
struct NotificationData: Codable {
    let type: String?
    let pollId: String?
    let winner: String?
    let yesCount: Int?
    let noCount: Int?
}

// MARK: - Responses
struct NotificationListResponse: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
}

struct ReadAllResponse: Codable {
    let userId: String
    let unreadCount: Int
}

struct DeviceRegisterResponse: Codable {
    let userId: String
    let registered: Bool
}
