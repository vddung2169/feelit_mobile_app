import Foundation

// MARK: - ExploreViewModel
/// Logic cho `ExploreViewController`: categories + assets + investors (mock) + lựa chọn category.
/// KHÔNG import UIKit.
final class ExploreViewModel {

    let categories = ["Tất cả", "Chứng khoán", "Crypto", "Vàng", "Forex", "Hàng hóa"]
    let assets = FEMock.assets
    let investors = FEMock.investors

    private(set) var selectedCategory = 0

    func selectCategory(_ index: Int) {
        guard categories.indices.contains(index) else { return }
        selectedCategory = index
    }
}
