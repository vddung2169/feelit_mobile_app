import Foundation

// MARK: - PortfolioViewModel
/// Logic cho `PortfolioViewController`: user + dự đoán gần đây + hiệu suất 7 ngày (mock).
/// KHÔNG import UIKit.
final class PortfolioViewModel {

    let user = FEMock.user
    let predictions = FEMock.predictions

    /// Độ chính xác 7 ngày gần nhất (0...1) cho biểu đồ hiệu suất.
    let performanceValues: [Double] = [0.45, 0.52, 0.48, 0.61, 0.58, 0.7, 0.73]
}
