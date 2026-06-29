import UIKit

// MARK: - DetailLineChartView
/// Biểu đồ đường 2 series (CÓ xanh / KHÔNG đỏ) cho màn chi tiết poll (Figma 233-5702).
/// Vẽ bằng CoreGraphics: lưới ngang + nhãn trục + 2 đường.
final class DetailLineChartView: UIView {

    var yesSeries: [CGFloat] = [] { didSet { setNeedsDisplay() } }   // 0...1
    var noSeries: [CGFloat] = []  { didSet { setNeedsDisplay() } }
    var yLabels: [String] = ["80k", "60k", "40k", "20k", "0"]
    var xLabels: [String] = ["Sep 21", "Sep 22", "Sep 23", "Sep 24"]

    private let leftPad: CGFloat = 34
    private let bottomPad: CGFloat = 20
    private let topPad: CGFloat = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let plot = CGRect(x: leftPad, y: topPad,
                          width: bounds.width - leftPad - 6,
                          height: bounds.height - topPad - bottomPad)

        // Lưới ngang + nhãn trục Y (Figma light: #E8E8E8)
        let gridColor = UIColor(hex: 0xE8E8E8)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor(hex: 0xA3A3A3),
        ]
        let rows = yLabels.count
        for i in 0..<rows {
            let y = plot.minY + plot.height * CGFloat(i) / CGFloat(rows - 1)
            ctx.setStrokeColor(gridColor.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: plot.minX, y: y))
            ctx.addLine(to: CGPoint(x: plot.maxX, y: y))
            ctx.strokePath()
            (yLabels[i] as NSString).draw(
                at: CGPoint(x: 4, y: y - 5), withAttributes: labelAttrs)
        }

        // Nhãn trục X
        if xLabels.count > 1 {
            for (i, t) in xLabels.enumerated() {
                let x = plot.minX + plot.width * CGFloat(i) / CGFloat(xLabels.count - 1)
                (t as NSString).draw(at: CGPoint(x: x - 8, y: plot.maxY + 6), withAttributes: labelAttrs)
            }
        }

        drawLine(noSeries, color: UIColor(hex: 0xF44336), in: plot, ctx: ctx)
        drawLine(yesSeries, color: UIColor(hex: 0x4CAF50), in: plot, ctx: ctx)
    }

    private func drawLine(_ data: [CGFloat], color: UIColor, in plot: CGRect, ctx: CGContext) {
        guard data.count > 1 else { return }
        let path = UIBezierPath()
        for (i, v) in data.enumerated() {
            let x = plot.minX + plot.width * CGFloat(i) / CGFloat(data.count - 1)
            let y = plot.maxY - plot.height * min(max(v, 0), 1)
            let p = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        color.setStroke()
        path.lineWidth = 2
        path.lineJoinStyle = .round
        path.stroke()
    }
}
