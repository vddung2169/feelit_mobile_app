import UIKit
import SwiftUI
import Charts

// MARK: - PollChartEntry
struct PollChartEntry: Identifiable {
    let id = UUID()
    let index: Int
    let yes: Double   // 0...100
    let no: Double    // 0...100
}

// MARK: - PollChartModel
/// Observable để SwiftUI Chart tự cập nhật khi nhận vote_update realtime.
final class PollChartModel: ObservableObject {
    @Published var entries: [PollChartEntry] = []
}

// MARK: - PollChartContent (Swift Charts)
/// 2 đường YES (xanh) / NO (đỏ) theo % theo thời gian, dùng Apple Swift Charts.
struct PollChartContent: View {
    @ObservedObject var model: PollChartModel

    private let yes = "YES"
    private let no = "NO"

    var body: some View {
        if model.entries.count < 2 {
            Text("Waiting for votes...")
                .font(.system(size: 13))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                ForEach(model.entries) { entry in
                    LineMark(x: .value("Lần", entry.index),
                             y: .value("%", entry.yes))
                        .foregroundStyle(by: .value("Phe", yes))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    LineMark(x: .value("Lần", entry.index),
                             y: .value("%", entry.no))
                        .foregroundStyle(by: .value("Phe", no))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }
            }
            .chartForegroundStyleScale([
                yes: Color(uiColor: .systemGreen),
                no: Color(uiColor: .systemRed),
            ])
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        }
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartLegend(position: .top, alignment: .trailing, spacing: 4)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - PollChartView (UIKit wrapper)
/// Giữ nguyên API cũ (`setData`) để PollViewController không phải đổi.
/// Bên trong host SwiftUI Swift Charts qua UIHostingController.
final class PollChartView: UIView {

    private let model = PollChartModel()
    private lazy var host = UIHostingController(rootView: PollChartContent(model: model))

    override init(frame: CGRect) {
        super.init(frame: frame)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public API (giữ nguyên)
    func setData(_ entries: [(yes: Double, no: Double)]) {
        model.entries = entries.enumerated().map {
            PollChartEntry(index: $0.offset, yes: $0.element.yes, no: $0.element.no)
        }
    }

    // Gắn hosting controller vào VC cha để lifecycle chuẩn.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let parentVC = parentViewController, host.parent == nil {
            parentVC.addChild(host)
            host.didMove(toParent: parentVC)
        }
    }
}

// MARK: - Helper
private extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController { return vc }
            responder = next
        }
        return nil
    }
}
