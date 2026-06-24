import Foundation

// MARK: - PollFeedViewModel
/// Logic cho `PollFeedViewController`: chủ đề + lọc thẻ poll theo chủ đề (mock).
/// KHÔNG import UIKit.
final class PollFeedViewModel {

    let categories = PollFeedData.categories
    private(set) var selectedCategory: String
    private(set) var items: [PollCardItem] = []

    init() {
        selectedCategory = PollFeedData.categories.first ?? "Xu hướng"
        applyFilter()
    }

    func selectCategory(_ index: Int) {
        guard categories.indices.contains(index) else { return }
        selectedCategory = categories[index]
        applyFilter()
    }

    private func applyFilter() {
        items = selectedCategory == "Xu hướng"
            ? PollFeedData.items
            : PollFeedData.items.filter { $0.category == selectedCategory }
    }
}
