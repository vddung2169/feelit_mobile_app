import UIKit

// MARK: - Color helper
extension UIColor {
    /// Khởi tạo từ hex "#RRGGBB" hoặc "RRGGBB".
    convenience init(hex: String, alpha: CGFloat = 1) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Models

/// Một lựa chọn vote trong card.
struct NewsOption {
    let title: String
    let percent: Int
    /// Text phụ hiển thị bên cạnh (vd "62% · 12k"). Nếu nil sẽ tự hiện "\(percent)%".
    let detail: String?
    /// Màu thanh fill.
    let tint: UIColor
    /// Đánh dấu lựa chọn đang dẫn đầu (viền sáng).
    let highlighted: Bool

    init(title: String, percent: Int, detail: String? = nil,
         tint: UIColor = UIColor(white: 1, alpha: 0.12), highlighted: Bool = false) {
        self.title = title
        self.percent = percent
        self.detail = detail
        self.tint = tint
        self.highlighted = highlighted
    }
}

/// Một flash card poll (full màn hình, vuốt lên để xem card kế tiếp).
struct NewsCard {
    enum Layout { case binary, multiple }

    let badge: String
    let badgeColor: UIColor
    let author: String
    let verified: Bool
    let closing: String
    let context: String?
    let question: String
    let questionColor: UIColor
    let layout: Layout
    let options: [NewsOption]
    let footer: String
    /// Màu gradient nền (2–3 màu, từ trên xuống).
    let gradient: [UIColor]
    /// Box phần trăm lớn ở góc phải (chỉ dùng cho card binary). (value, label, color)
    let headline: (value: String, label: String, color: UIColor)?
    /// Vẽ đường giá tăng + nến trang trí lên nền.
    let showsChart: Bool

    init(badge: String, badgeColor: UIColor = UIColor(hex: "#E5484D"),
         author: String = "Miquant", verified: Bool = true,
         closing: String, context: String? = nil,
         question: String, questionColor: UIColor = .white,
         layout: Layout, options: [NewsOption], footer: String,
         gradient: [UIColor],
         headline: (value: String, label: String, color: UIColor)? = nil,
         showsChart: Bool = false) {
        self.badge = badge
        self.badgeColor = badgeColor
        self.author = author
        self.verified = verified
        self.closing = closing
        self.context = context
        self.question = question
        self.questionColor = questionColor
        self.layout = layout
        self.options = options
        self.footer = footer
        self.gradient = gradient
        self.headline = headline
        self.showsChart = showsChart
    }
}

// MARK: - Sample data (fix sẵn, không gọi backend)
enum NewsSampleData {
    static let bull = UIColor(hex: "#4ADE80")
    static let gold = UIColor(hex: "#FFD66B")
    static let blue = UIColor(hex: "#7DD3FC")

    static let cards: [NewsCard] = [
        // 1 — VN-Index (city)
        NewsCard(
            badge: "TIN NÓNG",
            closing: "đóng sau 3 ngày",
            context: "Khối ngoại mua ròng 5 phiên liên tiếp",
            question: "VN-Index vượt 1.350 điểm tuần này?",
            layout: .binary,
            options: [
                NewsOption(title: "Tăng", percent: 62, detail: "62% · 12k",
                           tint: bull.withAlphaComponent(0.35), highlighted: true),
                NewsOption(title: "Giảm", percent: 38, detail: "38% · 7,4k"),
            ],
            footer: "+50 XP nếu đúng · 2,3k bình luận",
            gradient: [UIColor(hex: "#231557"), UIColor(hex: "#44107A"), UIColor(hex: "#FF1361")],
            headline: ("62%", "KHẢ NĂNG TĂNG", bull),
            showsChart: true
        ),

        // 2 — Vàng SJC (gold, multiple)
        NewsCard(
            badge: "SJC lập đỉnh 126tr/lượng",
            badgeColor: UIColor(hex: "#C99213"),
            closing: "đóng 31/7",
            question: "Giá vàng SJC cuối tháng 7 ở vùng nào?",
            layout: .multiple,
            options: [
                NewsOption(title: "Dưới 120 triệu", percent: 18),
                NewsOption(title: "120 – 130 triệu", percent: 34, tint: gold.withAlphaComponent(0.22)),
                NewsOption(title: "130 – 140 triệu", percent: 41, tint: gold.withAlphaComponent(0.30), highlighted: true),
                NewsOption(title: "Trên 140 triệu", percent: 7),
            ],
            footer: "8,4k dự đoán · +60 XP nếu đúng",
            gradient: [UIColor(hex: "#2B1D0E"), UIColor(hex: "#6D4C0F"), UIColor(hex: "#C99213")]
        ),

        // 3 — Fed (blue/orange)
        NewsCard(
            badge: "TIN NÓNG",
            closing: "kết quả 19/6",
            context: "CPI Mỹ thấp hơn dự báo · Fed họp tuần này",
            question: "Fed sẽ giảm lãi suất trong cuộc họp tháng 6?",
            layout: .binary,
            options: [
                NewsOption(title: "Có", percent: 58, detail: "58% · 11k",
                           tint: blue.withAlphaComponent(0.30), highlighted: true),
                NewsOption(title: "Không", percent: 42, detail: "42% · 8,1k"),
            ],
            footer: "19.204 người đã dự đoán · +50 XP",
            gradient: [UIColor(hex: "#0E3B5E"), UIColor(hex: "#1C6E8C"), UIColor(hex: "#F4A259")],
            headline: ("58%", "KHẢ NĂNG GIẢM LS", blue)
        ),

        // 4 — BTC (purple/pink)
        NewsCard(
            badge: "CRYPTO",
            badgeColor: UIColor(hex: "#F72585"),
            closing: "đóng cuối năm",
            context: "BTC ETF hút ròng kỷ lục",
            question: "BTC vượt $150k trong năm nay?",
            layout: .binary,
            options: [
                NewsOption(title: "Có", percent: 71, detail: "71% · 8,1k",
                           tint: bull.withAlphaComponent(0.35), highlighted: true),
                NewsOption(title: "Không", percent: 29, detail: "29% · 3,3k"),
            ],
            footer: "11,4k dự đoán · +70 XP nếu đúng",
            gradient: [UIColor(hex: "#0F0524"), UIColor(hex: "#3A0CA3"), UIColor(hex: "#F72585")],
            headline: ("71%", "KHẢ NĂNG CÓ", bull),
            showsChart: true
        ),

        // 5 — USD/VND (green forex)
        NewsCard(
            badge: "TỶ GIÁ",
            badgeColor: UIColor(hex: "#10B981"),
            closing: "đóng 30/9",
            context: "DXY mạnh lên · NHNN bán USD can thiệp",
            question: "Tỷ giá USD/VND vượt 26.000 trong quý này?",
            layout: .binary,
            options: [
                NewsOption(title: "Có", percent: 47, detail: "47% · 2,4k",
                           tint: bull.withAlphaComponent(0.30)),
                NewsOption(title: "Không", percent: 53, detail: "53% · 2,7k",
                           tint: UIColor(white: 1, alpha: 0.14), highlighted: true),
            ],
            footer: "5,1k dự đoán · +40 XP nếu đúng",
            gradient: [UIColor(hex: "#0B2A4A"), UIColor(hex: "#1E5F74"), UIColor(hex: "#2EC4B6")],
            headline: ("53%", "NGHIÊNG KHÔNG VƯỢT", blue),
            showsChart: true
        ),

        // 6 — Dầu Brent (oil, multiple)
        NewsCard(
            badge: "OPEC+ gia hạn cắt giảm",
            badgeColor: UIColor(hex: "#FF8F00"),
            closing: "đóng 31/12",
            question: "Giá dầu Brent cuối năm ở vùng nào?",
            layout: .multiple,
            options: [
                NewsOption(title: "Dưới $70", percent: 22),
                NewsOption(title: "$70 – $85", percent: 45,
                           tint: UIColor(hex: "#FF8F00").withAlphaComponent(0.28), highlighted: true),
                NewsOption(title: "$85 – $100", percent: 26,
                           tint: UIColor(hex: "#FF8F00").withAlphaComponent(0.18)),
                NewsOption(title: "Trên $100", percent: 7),
            ],
            footer: "6,7k dự đoán · +60 XP nếu đúng",
            gradient: [UIColor(hex: "#14130F"), UIColor(hex: "#3E2723"), UIColor(hex: "#FF8F00")]
        ),
    ]
}
