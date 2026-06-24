import Foundation

// MARK: - NewsViewModel
/// Logic cho `NewsViewController`: danh sách flash card (mock) + lưu lựa chọn vote theo card.
/// KHÔNG import UIKit.
final class NewsViewModel {

    let cards = NewsSampleData.cards

    /// Lựa chọn đã vote cho từng card (item index -> option index). Giữ lại khi cuộn.
    private(set) var votes: [Int: Int] = [:]

    func vote(card index: Int, option: Int) { votes[index] = option }
    func vote(for index: Int) -> Int? { votes[index] }
}
