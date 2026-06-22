import Foundation

// MARK: - Message
/// Tin nhắn chat. Field từ server ở dạng snake_case (sender_id, ...).
struct Message: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, content
        case senderId   = "senderId"
        case receiverId = "receiverId"
        case createdAt  = "createdAt"
    }

    /// ID của user đang đăng nhập — set khi login (xem ChatLoginViewController).
    /// Dùng để phân biệt bubble trái/phải.
    static var currentUserId: String = ""

    var isSentByMe: Bool {
        senderId == Message.currentUserId
    }

    /// Parse createdAt (ISO8601) → "HH:mm". Fallback chuỗi rỗng nếu parse fail.
    var formattedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: createdAt)
            ?? ISO8601DateFormatter().date(from: createdAt)

        guard let date = date else { return "" }

        let out = DateFormatter()
        out.dateFormat = "HH:mm"
        return out.string(from: date)
    }

    // MARK: - Poll sharing
    /// Nếu message này là 1 poll được share → trả payload, ngược lại nil.
    var sharedPoll: SharedPoll? {
        SharedPoll.decode(from: content)
    }
}

// MARK: - SharedPoll
/// Payload của 1 poll được share vào chat (giống share bài viết FB vào tin nhắn).
/// Được nhúng trong `Message.content` dạng: PREFIX + JSON, nên KHÔNG cần đổi backend
/// — tin vẫn lưu/broadcast qua API messages như tin thường.
struct SharedPoll: Codable {
    let pollId: String
    let title: String
    let status: String?

    /// Marker khó trùng nội dung gõ tay.
    static let prefix = "\u{1F4CA}POLL_SHARE::"   // 📊POLL_SHARE::

    /// Tạo `content` để gửi qua sendMessage khi share 1 poll.
    static func encode(pollId: String, title: String, status: String?) -> String {
        let payload = SharedPoll(pollId: pollId, title: title, status: status)
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return title   // fallback: gửi như tin thường
        }
        return prefix + json
    }

    /// Parse ngược từ `content`. Trả nil nếu không phải poll share.
    static func decode(from content: String) -> SharedPoll? {
        guard content.hasPrefix(prefix) else { return nil }
        let json = String(content.dropFirst(prefix.count))
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SharedPoll.self, from: data)
    }
}
