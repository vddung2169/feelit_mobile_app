import SwiftUI

// MARK: - Color helper
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

// MARK: - Models (self-contained cho widget, data fix sẵn)
struct WidgetOption {
    let title: String
    let percent: Int
    let detail: String?
    let tintHex: String
    let tintAlpha: Double
    let highlighted: Bool

    init(_ title: String, _ percent: Int, detail: String? = nil,
         tintHex: String = "#FFFFFF", tintAlpha: Double = 0.14, highlighted: Bool = false) {
        self.title = title
        self.percent = percent
        self.detail = detail
        self.tintHex = tintHex
        self.tintAlpha = tintAlpha
        self.highlighted = highlighted
    }

    var tint: Color { Color(hex: tintHex).opacity(tintAlpha) }
}

struct WidgetHeadline {
    let value: String
    let label: String
    let colorHex: String
}

struct WidgetCard: Identifiable {
    enum Layout { case binary, multiple }

    let id = UUID()
    let badge: String
    let badgeHex: String
    let author: String
    let closing: String
    let question: String
    let layout: Layout
    let options: [WidgetOption]
    let footer: String
    let gradient: [String]
    let headline: WidgetHeadline?

    var gradientColors: [Color] { gradient.map { Color(hex: $0) } }
}

// MARK: - Sample data (cùng nội dung với feed trong app)
enum WidgetSampleData {
    static let bull = "#4ADE80"
    static let gold = "#FFD66B"
    static let blue = "#7DD3FC"

    static let cards: [WidgetCard] = [
        WidgetCard(
            badge: "TIN NÓNG", badgeHex: "#E5484D", author: "Miquant", closing: "đóng sau 3 ngày",
            question: "VN-Index vượt 1.350 điểm tuần này?",
            layout: .binary,
            options: [
                WidgetOption("Tăng", 62, detail: "62%", tintHex: bull, tintAlpha: 0.35, highlighted: true),
                WidgetOption("Giảm", 38, detail: "38%"),
            ],
            footer: "+50 XP · 2,3k bình luận",
            gradient: ["#231557", "#44107A", "#FF1361"],
            headline: WidgetHeadline(value: "62%", label: "KHẢ NĂNG TĂNG", colorHex: bull)
        ),
        WidgetCard(
            badge: "SJC đỉnh 126tr", badgeHex: "#C99213", author: "Miquant", closing: "đóng 31/7",
            question: "Giá vàng SJC cuối tháng 7 ở vùng nào?",
            layout: .multiple,
            options: [
                WidgetOption("Dưới 120 triệu", 18),
                WidgetOption("120 – 130 triệu", 34, tintHex: gold, tintAlpha: 0.22),
                WidgetOption("130 – 140 triệu", 41, tintHex: gold, tintAlpha: 0.30, highlighted: true),
                WidgetOption("Trên 140 triệu", 7),
            ],
            footer: "8,4k dự đoán · +60 XP",
            gradient: ["#2B1D0E", "#6D4C0F", "#C99213"],
            headline: nil
        ),
        WidgetCard(
            badge: "TIN NÓNG", badgeHex: "#E5484D", author: "Miquant", closing: "kết quả 19/6",
            question: "Fed sẽ giảm lãi suất trong cuộc họp tháng 6?",
            layout: .binary,
            options: [
                WidgetOption("Có", 58, detail: "58%", tintHex: blue, tintAlpha: 0.30, highlighted: true),
                WidgetOption("Không", 42, detail: "42%"),
            ],
            footer: "19.204 dự đoán · +50 XP",
            gradient: ["#0E3B5E", "#1C6E8C", "#F4A259"],
            headline: WidgetHeadline(value: "58%", label: "KHẢ NĂNG GIẢM LS", colorHex: blue)
        ),
        WidgetCard(
            badge: "CRYPTO", badgeHex: "#F72585", author: "Miquant", closing: "đóng cuối năm",
            question: "BTC vượt $150k trong năm nay?",
            layout: .binary,
            options: [
                WidgetOption("Có", 71, detail: "71%", tintHex: bull, tintAlpha: 0.35, highlighted: true),
                WidgetOption("Không", 29, detail: "29%"),
            ],
            footer: "11,4k dự đoán · +70 XP",
            gradient: ["#0F0524", "#3A0CA3", "#F72585"],
            headline: WidgetHeadline(value: "71%", label: "KHẢ NĂNG CÓ", colorHex: bull)
        ),
        WidgetCard(
            badge: "TỶ GIÁ", badgeHex: "#10B981", author: "Miquant", closing: "đóng 30/9",
            question: "Tỷ giá USD/VND vượt 26.000 trong quý này?",
            layout: .binary,
            options: [
                WidgetOption("Có", 47, detail: "47%", tintHex: bull, tintAlpha: 0.30),
                WidgetOption("Không", 53, detail: "53%", highlighted: true),
            ],
            footer: "5,1k dự đoán · +40 XP",
            gradient: ["#0B2A4A", "#1E5F74", "#2EC4B6"],
            headline: WidgetHeadline(value: "53%", label: "NGHIÊNG KHÔNG", colorHex: blue)
        ),
        WidgetCard(
            badge: "OPEC+ cắt giảm", badgeHex: "#FF8F00", author: "Miquant", closing: "đóng 31/12",
            question: "Giá dầu Brent cuối năm ở vùng nào?",
            layout: .multiple,
            options: [
                WidgetOption("Dưới $70", 22),
                WidgetOption("$70 – $85", 45, tintHex: "#FF8F00", tintAlpha: 0.28, highlighted: true),
                WidgetOption("$85 – $100", 26, tintHex: "#FF8F00", tintAlpha: 0.18),
                WidgetOption("Trên $100", 7),
            ],
            footer: "6,7k dự đoán · +60 XP",
            gradient: ["#14130F", "#3E2723", "#FF8F00"],
            headline: nil
        ),
    ]
}
