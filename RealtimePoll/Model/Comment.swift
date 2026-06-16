import Foundation

// MARK: - Comment
/// Bình luận của 1 post. Server trả camelCase (postId, userId, createdAt) nên
/// decode trực tiếp được, không cần CodingKeys.
struct Comment: Codable {
    let id: String
    let postId: String
    let userId: String
    let username: String
    let content: String
    let createdAt: String

    /// Parse createdAt (ISO8601). "HH:mm" nếu là hôm nay, ngược lại "dd/MM".
    var formattedTime: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: createdAt)
            ?? ISO8601DateFormatter().date(from: createdAt)

        guard let date = date else { return "" }

        let out = DateFormatter()
        out.locale = Locale(identifier: "vi_VN")
        out.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "dd/MM"
        return out.string(from: date)
    }

    /// Ký tự đầu của username, viết hoa (cho avatar).
    var avatarLetter: String {
        username.first.map { String($0).uppercased() } ?? "?"
    }
}
