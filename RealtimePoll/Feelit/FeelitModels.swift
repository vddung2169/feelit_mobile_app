import Foundation
import UIKit

// MARK: - Models
// Prefix "FE" để tránh trùng tên `Poll` đã có sẵn trong project (Model/Poll.swift).

struct FEPoll {
    let id: String
    let title: String
    let asset: String
    var yesCount: Int
    var noCount: Int
    let endsIn: String

    var total: Int { yesCount + noCount }
    var yesPercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(yesCount) / Double(total) * 100).rounded())
    }
    var noPercent: Int { total > 0 ? 100 - yesPercent : 0 }
    var votesText: String {
        total >= 1000 ? String(format: "%.1fk votes", Double(total) / 1000) : "\(total) votes"
    }
}

struct FEPost {
    let id: String
    let user: String
    let badge: String
    let accuracy: Int
    let content: String
    let tags: [String]
    var likes: Int
    let comments: Int
    let hasVote: Bool
    let timestamp: String
    var embeddedPoll: FEPoll?
}

// MARK: - PostDTO
/// Decode response GET /api/posts (camelCase). Field optional cho an toàn nếu BE thiếu.
struct PostDTO: Codable {
    let id: String
    let userId: String?
    let username: String?
    let badge: String?
    let content: String
    let tags: [String]?
    let likes: Int?
    let commentCount: Int?
    let createdAt: String?
    let pollId: String?

    /// Map sang model UV dùng (FEPost).
    func toFEPost() -> FEPost {
        FEPost(
            id: id,
            user: username ?? userId ?? "user",
            badge: badge ?? "",
            accuracy: 0,
            content: content,
            tags: tags ?? [],
            likes: likes ?? 0,
            comments: commentCount ?? 0,
            hasVote: pollId != nil,
            timestamp: PostDTO.relativeTime(createdAt),
            embeddedPoll: nil
        )
    }

    /// ISO8601 → chuỗi tương đối kiểu "2 phút trước".
    static func relativeTime(_ iso: String?) -> String {
        guard let iso = iso else { return "" }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let date = date else { return "" }
        let rel = RelativeDateTimeFormatter()
        rel.locale = Locale(identifier: "vi_VN")
        rel.unitsStyle = .short
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

struct FEUser {
    let username: String
    let bio: String
    let accuracy: Int
    let rank: Int
    let totalUsers: Int
    let totalVotes: Int
    let correctVotes: Int
    let streak: Int
    let points: Int
    let followers: Int
    let following: Int
    let badges: [FEBadge]
}

struct FEBadge {
    let icon: String
    let name: String
    let unlocked: Bool
}

struct FEAsset {
    let ticker: String
    let name: String
    let bullish: Int   // 0...100
    let votes: Int
}

struct FEInvestor {
    let username: String
    let accuracy: Int
    let streak: Int
}

struct FEPrediction {
    let asset: String
    let isBullish: Bool
    let result: FEResult
    let timestamp: String
}

enum FEResult {
    case correct, wrong, pending
}

struct FEActivity {
    let icon: String
    let text: String
    let timestamp: String
}

// MARK: - FlashCard
/// Thẻ poll toàn màn hình kiểu Locket (màn "Xem tất cả" của Đang Hot).
struct FlashCard {
    let badge: String          // "TIN NÓNG" / "SJC lập đỉnh"...
    let statLabel: String      // "KHẢ NĂNG TĂNG"
    let author: String
    let context: String        // dòng phụ nhỏ
    let question: String
    let yesLabel: String       // "Tăng"
    let noLabel: String        // "Giảm"
    let yesPercent: Int        // 0...100
    let votesText: String      // "19k"
    let endsIn: String         // "đóng sau 3 ngày"
    let xp: Int
    let comments: Int
    let gradient: [UInt32]     // hex stops cho nền
    let illustration: IllustrationKind

    var noPercent: Int { 100 - yesPercent }
    var gradientColors: [CGColor] { gradient.map { UIColor(hex: $0).cgColor } }
}

// MARK: - Mock Data
enum FEMock {

    static let flashCards: [FlashCard] = [
        FlashCard(badge: "TIN NÓNG", statLabel: "KHẢ NĂNG TĂNG", author: "Miquant",
                  context: "Khối ngoại mua ròng 5 phiên liên tiếp",
                  question: "VN-Index vượt 1.350 điểm tuần này?",
                  yesLabel: "Tăng", noLabel: "Giảm", yesPercent: 62, votesText: "19k",
                  endsIn: "đóng sau 3 ngày", xp: 50, comments: 2300,
                  gradient: [0x231557, 0x44107A, 0xFF1361], illustration: .skyline),
        FlashCard(badge: "SJC LẬP ĐỈNH", statLabel: "KHẢ NĂNG TĂNG", author: "GoldDesk",
                  context: "Vàng thế giới vượt 2.400 USD/oz",
                  question: "Giá vàng SJC chạm 130 triệu/lượng tháng này?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 71, votesText: "8.4k",
                  endsIn: "đóng 31/7", xp: 60, comments: 940,
                  gradient: [0x2B1D0E, 0x6D4C0F, 0xC99213], illustration: .goldBars),
        FlashCard(badge: "CRYPTO", statLabel: "KHẢ NĂNG ĐẠT", author: "ChainVN",
                  context: "BTC tái kiểm tra vùng 95k, whale gom hàng",
                  question: "Bitcoin đạt 100k USD trước Q3 2026?",
                  yesLabel: "Đạt", noLabel: "Không", yesPercent: 58, votesText: "12k",
                  endsIn: "đóng sau 5 ngày", xp: 70, comments: 1800,
                  gradient: [0x0B0B1E, 0x3A1C71, 0xF7931A], illustration: .coinBTC),
        FlashCard(badge: "FED", statLabel: "KHẢ NĂNG GIẢM", author: "MacroEye",
                  context: "CPI Mỹ thấp hơn dự báo · Fed họp tuần này",
                  question: "Fed sẽ giảm lãi suất trong cuộc họp tháng 6?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 64, votesText: "19k",
                  endsIn: "kết quả 19/6", xp: 50, comments: 3100,
                  gradient: [0x0E3B5E, 0x1C6E8C, 0xF4A259], illustration: .columns),
        FlashCard(badge: "CÔNG NGHỆ", statLabel: "KHẢ NĂNG ĐẠT", author: "TechVN",
                  context: "FPT ký loạt hợp đồng AI tỷ đô",
                  question: "FPT giữ tăng trưởng EPS 25% năm 2026?",
                  yesLabel: "Đạt", noLabel: "Không", yesPercent: 55, votesText: "1.2k",
                  endsIn: "đóng sau 7 ngày", xp: 40, comments: 420,
                  gradient: [0x0F2027, 0x203A43, 0x2C5364], illustration: .candles),
        FlashCard(badge: "TỶ GIÁ", statLabel: "KHẢ NĂNG VƯỢT", author: "FXdesk",
                  context: "NHNN bán USD can thiệp tỷ giá",
                  question: "USD/VND vượt 26.000 trong tháng 7?",
                  yesLabel: "Vượt", noLabel: "Không", yesPercent: 43, votesText: "3.1k",
                  endsIn: "đóng 31/7", xp: 50, comments: 610,
                  gradient: [0x134E5E, 0x2E7D6E, 0x71B280], illustration: .coinUSD),
        FlashCard(badge: "HÀNG HOÁ", statLabel: "KHẢ NĂNG GIẢM", author: "OilWatch",
                  context: "OPEC+ cân nhắc tăng sản lượng",
                  question: "Giá dầu Brent về dưới 70 USD tháng này?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 48, votesText: "2.0k",
                  endsIn: "đóng sau 4 ngày", xp: 50, comments: 380,
                  gradient: [0x232526, 0x33373A, 0x414345], illustration: .barrel),
        FlashCard(badge: "NGÂN HÀNG", statLabel: "KHẢ NĂNG TĂNG", author: "BankVN",
                  context: "Tín dụng tăng tốc cuối quý",
                  question: "Nhóm cổ phiếu ngân hàng dẫn sóng tháng 7?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 67, votesText: "4.5k",
                  endsIn: "đóng sau 6 ngày", xp: 50, comments: 720,
                  gradient: [0x1A2980, 0x1E6FAF, 0x26D0CE], illustration: .columns),
        FlashCard(badge: "BẤT ĐỘNG SẢN", statLabel: "KHẢ NĂNG PHỤC HỒI", author: "REVN",
                  context: "Luật đất đai mới có hiệu lực",
                  question: "BĐS phục hồi rõ nét trong nửa cuối 2026?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 51, votesText: "1.8k",
                  endsIn: "đóng sau 10 ngày", xp: 60, comments: 530,
                  gradient: [0x3E5151, 0x8A8170, 0xDECBA4], illustration: .skyline),
        FlashCard(badge: "THÉP", statLabel: "KHẢ NĂNG TĂNG", author: "SteelVN",
                  context: "Giá thép xây dựng tăng 3 tuần liên tiếp",
                  question: "HPG vượt đỉnh cũ trong quý này?",
                  yesLabel: "Có", noLabel: "Không", yesPercent: 45, votesText: "2.7k",
                  endsIn: "đóng sau 8 ngày", xp: 50, comments: 690,
                  gradient: [0x42275A, 0x5E2E6B, 0x734B6D], illustration: .candles),
    ]


    static let polls: [FEPoll] = [
        FEPoll(id: "1", title: "VN-INDEX sẽ vượt 1,300 điểm trong tuần này?",
               asset: "#VN-INDEX", yesCount: 1842, noCount: 756, endsIn: "2 giờ 30 phút"),
        FEPoll(id: "2", title: "Vàng SJC sẽ tăng vượt 90 triệu/lượng tháng này?",
               asset: "#GOLD", yesCount: 934, noCount: 1205, endsIn: "1 ngày"),
        FEPoll(id: "3", title: "Bitcoin sẽ đạt 100k USD trước Q3 2026?",
               asset: "#BTC", yesCount: 2341, noCount: 891, endsIn: "5 ngày"),
        FEPoll(id: "4", title: "FPT có thể duy trì tăng trưởng EPS 25% năm 2026?",
               asset: "#FPT", yesCount: 567, noCount: 423, endsIn: "3 giờ"),
    ]

    static let posts: [FEPost] = [
        FEPost(id: "p1", user: "nguyentrader", badge: "⚡ PRO", accuracy: 87,
               content: "VN-INDEX đang tích lũy tại vùng 1,270-1,280. Theo tôi đây là vùng hỗ trợ mạnh, khả năng cao sẽ bứt phá lên 1,300+ trong tuần tới. Risk/Reward khá tốt để entry tại đây.",
               tags: ["#VN-INDEX", "#Market"], likes: 234, comments: 45, hasVote: true,
               timestamp: "2 phút trước", embeddedPoll: polls[0]),
        FEPost(id: "p2", user: "goldmaster", badge: "🔥 HOT", accuracy: 72,
               content: "Vàng đang trong xu hướng tăng mạnh. Fed có thể cắt giảm lãi suất thêm 2 lần trong năm nay. Tích lũy vàng vật chất dưới 85 triệu là hợp lý.",
               tags: ["#GOLD", "#Fed"], likes: 189, comments: 32, hasVote: false,
               timestamp: "18 phút trước", embeddedPoll: nil),
        FEPost(id: "p3", user: "cryptobull", badge: "🚀", accuracy: 61,
               content: "BTC đang tái kiểm tra vùng 95k. On-chain data cho thấy whale đang accumulate. Target ngắn hạn 105k.",
               tags: ["#BTC", "#Crypto"], likes: 456, comments: 78, hasVote: true,
               timestamp: "1 giờ trước", embeddedPoll: polls[2]),
    ]

    static let user = FEUser(
        username: "trader_pro",
        bio: "Long-term investor • VN30 & Crypto • Risk-first mindset 📈",
        accuracy: 73, rank: 142, totalUsers: 2847,
        totalVotes: 47, correctVotes: 34, streak: 8, points: 1250,
        followers: 1284, following: 312,
        badges: [
            FEBadge(icon: "🎯", name: "Sniper", unlocked: true),
            FEBadge(icon: "🔥", name: "Hot Streak", unlocked: true),
            FEBadge(icon: "👑", name: "Top 10%", unlocked: true),
            FEBadge(icon: "💎", name: "Diamond", unlocked: false),
            FEBadge(icon: "🚀", name: "Early Bird", unlocked: false),
        ]
    )

    static let assets: [FEAsset] = [
        FEAsset(ticker: "VN-INDEX", name: "Chỉ số VN-Index", bullish: 68, votes: 2847),
        FEAsset(ticker: "FPT", name: "FPT Corporation", bullish: 81, votes: 1203),
        FEAsset(ticker: "HPG", name: "Hòa Phát Group", bullish: 45, votes: 876),
        FEAsset(ticker: "BTC", name: "Bitcoin", bullish: 72, votes: 3421),
        FEAsset(ticker: "GOLD", name: "Vàng SJC", bullish: 63, votes: 1567),
        FEAsset(ticker: "VNM", name: "Vinamilk", bullish: 55, votes: 654),
    ]

    static let investors: [FEInvestor] = [
        FEInvestor(username: "nguyentrader", accuracy: 87, streak: 12),
        FEInvestor(username: "goldmaster", accuracy: 72, streak: 5),
        FEInvestor(username: "cryptobull", accuracy: 61, streak: 3),
        FEInvestor(username: "valuehunter", accuracy: 79, streak: 9),
    ]

    static let predictions: [FEPrediction] = [
        FEPrediction(asset: "#VN-INDEX", isBullish: true, result: .correct, timestamp: "Hôm nay"),
        FEPrediction(asset: "#GOLD", isBullish: false, result: .wrong, timestamp: "Hôm qua"),
        FEPrediction(asset: "#BTC", isBullish: true, result: .pending, timestamp: "2 ngày trước"),
        FEPrediction(asset: "#FPT", isBullish: true, result: .correct, timestamp: "3 ngày trước"),
    ]

    static let activities: [FEActivity] = [
        FEActivity(icon: "✓", text: "Dự đoán đúng #VN-INDEX tăng", timestamp: "2 giờ trước"),
        FEActivity(icon: "🏆", text: "Mở khóa badge 'Top 10%'", timestamp: "Hôm qua"),
        FEActivity(icon: "🔥", text: "Đạt streak 8 ngày liên tiếp", timestamp: "Hôm qua"),
        FEActivity(icon: "📤", text: "Chia sẻ nhận định về #BTC", timestamp: "2 ngày trước"),
    ]

    /// % bullish toàn thị trường cho Market Pulse header.
    static let marketPulseBullish = 68
    static let marketPulseVoters = 2847
}
