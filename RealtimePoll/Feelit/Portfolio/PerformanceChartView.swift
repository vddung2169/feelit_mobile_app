import SwiftUI
import Charts

// MARK: - PerformancePoint
struct PerformancePoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double   // 0...1
}

// MARK: - PerformanceChart (Swift Charts)
/// Line chart hiệu suất 7 ngày dùng Apple Swift Charts.
/// Nhúng vào UIKit qua UIHostingController (xem PortfolioViewController).
struct PerformanceChart: View {

    let values: [Double]
    private let labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    private var points: [PerformancePoint] {
        Array(zip(labels, values)).map { PerformancePoint(day: $0.0, value: $0.1) }
    }

    private var primary: Color { Color(uiColor: FeelitColors.primary) }

    var body: some View {
        Chart {
            ForEach(points) { point in
                // Vùng gradient dưới đường line
                AreaMark(
                    x: .value("Ngày", point.day),
                    y: .value("Độ chính xác", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [primary.opacity(0.45), primary.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // Đường line
                LineMark(
                    x: .value("Ngày", point.day),
                    y: .value("Độ chính xác", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            // Dot trắng ở điểm cuối
            if let last = points.last {
                PointMark(
                    x: .value("Ngày", last.day),
                    y: .value("Độ chính xác", last.value)
                )
                .foregroundStyle(.white)
                .symbolSize(70)
            }
        }
        .chartYScale(domain: 0...1)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: labels) { _ in
                AxisValueLabel()
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(uiColor: FeelitColors.textTertiary))
            }
        }
    }
}
