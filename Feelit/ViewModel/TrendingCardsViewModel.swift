import Foundation

// MARK: - TrendingCardsViewModel
/// Logic cho `TrendingCardsViewController`: danh sách flash card (mock) + lựa chọn vote theo card.
/// KHÔNG import UIKit.
final class TrendingCardsViewModel {

    let cards = FEMock.flashCards

    /// Lựa chọn vote theo index card (true = YES). Giữ trạng thái khi cuộn qua lại.
    private(set) var votes: [Int: Bool] = [:]

    func vote(card index: Int, choseYes: Bool) { votes[index] = choseYes }
    func vote(for index: Int) -> Bool? { votes[index] }
}
