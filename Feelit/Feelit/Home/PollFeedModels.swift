import UIKit

// MARK: - PollCardItem
/// Một thẻ poll cho feed Home mới (Figma 219-5411 / chi tiết 233-5702).
/// Dữ liệu mock (BE chưa có cấu trúc card này).
struct PollCardItem {
    let id: String
    let category: String        // "Crypto"
    let cadence: String         // "Hàng giờ"
    let assetSymbol: String     // "BTC"
    let assetEmoji: String      // "₿"
    let assetColor: UInt32      // màu badge asset
    let title: String           // "Giá Bitcoin ngày mai lúc 10:00AM"
    let trending: Bool
    let currentPrice: String    // "$62,757" — giá ngưỡng để poll resolve "Tăng"
    let marketPrice: String     // "$69.660,27" — giá thị trường hiện tại
    let changePercent: String   // "11%"
    let isUp: Bool
    let yesPercent: Int
    let voters: Int
    let commentCount: Int
    let saveCount: Int
    let gradient: [UInt32]       // nền card (thay cho ảnh)

    var votersText: String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.groupingSeparator = "."
        let s = f.string(from: NSNumber(value: voters)) ?? "\(voters)"
        return "\(s) người đã chọn"
    }
    var gradientColors: [CGColor] { gradient.map { UIColor(hex: $0).cgColor } }
}

// MARK: - Categories
enum PollFeedData {
    static let categories = ["Xu hướng", "Chứng khoán VN", "Ngoại hối", "Crypto", "Kinh tế"]

    static let items: [PollCardItem] = [
        PollCardItem(id: "btc", category: "Crypto", cadence: "Hàng giờ",
                     assetSymbol: "BTC", assetEmoji: "₿", assetColor: 0xF7931A,
                     title: "Giá Bitcoin ngày mai lúc 10:00AM", trending: true,
                     currentPrice: "$62,757", marketPrice: "$69.660,27", changePercent: "11%", isUp: true,
                     yesPercent: 62, voters: 19204, commentCount: 213, saveCount: 81,
                     gradient: [0xD89A2E, 0xF7B733, 0xB8740F]),
        PollCardItem(id: "vnindex", category: "Chứng khoán VN", cadence: "Hàng ngày",
                     assetSymbol: "VNI", assetEmoji: "📈", assetColor: 0x00D085,
                     title: "VN-Index vượt 1.300 điểm trong tuần này?", trending: true,
                     currentPrice: "1.300", marketPrice: "1.302", changePercent: "0.8%", isUp: true,
                     yesPercent: 71, voters: 8421, commentCount: 142, saveCount: 56,
                     gradient: [0x1E9E60, 0x42D98E, 0x0E7A48]),
        PollCardItem(id: "eth", category: "Crypto", cadence: "Hàng giờ",
                     assetSymbol: "ETH", assetEmoji: "Ξ", assetColor: 0x627EEA,
                     title: "Ethereum chạm 4.000 USD cuối tháng?", trending: false,
                     currentPrice: "$4,000", marketPrice: "$3,412", changePercent: "3.2%", isUp: false,
                     yesPercent: 48, voters: 5210, commentCount: 88, saveCount: 31,
                     gradient: [0x4A55C8, 0x6B7BE8, 0x2A2F9E]),
        PollCardItem(id: "gold", category: "Ngoại hối", cadence: "Hàng ngày",
                     assetSymbol: "GOLD", assetEmoji: "🥇", assetColor: 0xFFB547,
                     title: "Vàng SJC vượt 90 triệu/lượng tháng này?", trending: false,
                     currentPrice: "90.0tr", marketPrice: "89.1tr", changePercent: "1.4%", isUp: true,
                     yesPercent: 64, voters: 12903, commentCount: 176, saveCount: 64,
                     gradient: [0xCC9A20, 0xF0C040, 0x9E7012]),
        PollCardItem(id: "usd", category: "Ngoại hối", cadence: "Hàng ngày",
                     assetSymbol: "USD", assetEmoji: "💵", assetColor: 0x2E7D32,
                     title: "USD/VND vượt 26.000 trong tháng 7?", trending: false,
                     currentPrice: "26.000", marketPrice: "25.380", changePercent: "0.3%", isUp: false,
                     yesPercent: 43, voters: 3120, commentCount: 61, saveCount: 22,
                     gradient: [0x1E9E72, 0x40C088, 0x0E6E50]),
    ]
}
