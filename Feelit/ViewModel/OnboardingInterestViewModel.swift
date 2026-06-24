import Foundation

// MARK: - OnboardingInterestViewModel
/// Logic cho `OnboardingInterestViewController`: danh sách chủ đề + lưu chủ đề đã chọn.
/// KHÔNG import UIKit.
final class OnboardingInterestViewModel {

    let topics = [
        "Chứng khoán VN", "Crypto", "Vàng", "Lãi suất & Fed", "Bất động sản",
        "Dầu & hàng hóa", "Công nghệ & AI", "Thể thao", "Giải trí",
        "Vĩ mô thế giới", "Cổ phiếu ngân hàng",
    ]

    private let interestsKey = "feelit_interests"

    func save(_ selected: Set<String>) {
        UserDefaults.standard.set(Array(selected), forKey: interestsKey)
    }
}
