import UIKit

// MARK: - IllustrationKind
/// Loại minh hoạ vẽ bằng CoreGraphics (thay cho SVG) cho mỗi flash card.
enum IllustrationKind {
    case skyline, goldBars, candles, columns, barrel, coinBTC, coinUSD
}

// MARK: - IllustrationView
/// Vẽ minh hoạ theo chủ đề bằng UIBezierPath/CoreGraphics, đặt giữa nền gradient
/// và lớp overlay tối của FlashCardCell.
final class IllustrationView: UIView {

    var kind: IllustrationKind = .skyline { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        switch kind {
        case .skyline:  drawSkyline(ctx, rect)
        case .goldBars: drawGoldBars(ctx, rect)
        case .candles:  drawCandles(ctx, rect)
        case .columns:  drawColumns(ctx, rect)
        case .barrel:   drawBarrel(ctx, rect)
        case .coinBTC:  drawCoin(ctx, rect, glyph: "₿", color: UIColor(hex: 0xFFC107))
        case .coinUSD:  drawCoin(ctx, rect, glyph: "$", color: UIColor(hex: 0x4ADE80))
        }
    }

    // MARK: Skyline (city + sun + đường giá tăng)
    private func drawSkyline(_ ctx: CGContext, _ r: CGRect) {
        let w = r.width, h = r.height
        let sunC = CGPoint(x: w * 0.78, y: h * 0.22), sunR = w * 0.12
        UIColor(hex: 0xFFE3B3).withAlphaComponent(0.22).setFill()
        ctx.fillEllipse(in: CGRect(x: sunC.x - sunR * 1.9, y: sunC.y - sunR * 1.9, width: sunR * 3.8, height: sunR * 3.8))
        UIColor(hex: 0xFFE3B3).withAlphaComponent(0.95).setFill()
        ctx.fillEllipse(in: CGRect(x: sunC.x - sunR, y: sunC.y - sunR, width: sunR * 2, height: sunR * 2))

        let base = h * 0.92
        UIColor.black.withAlphaComponent(0.30).setFill()
        let heights: [CGFloat] = [0.42, 0.55, 0.34, 0.64, 0.30, 0.50, 0.40]
        let bw = w / CGFloat(heights.count)
        for (i, frac) in heights.enumerated() {
            ctx.fill(CGRect(x: CGFloat(i) * bw + 2, y: base - h * frac, width: bw - 4, height: h * frac))
        }
        UIColor(hex: 0xFFD9A0).withAlphaComponent(0.75).setFill()
        for i in 0..<heights.count where i % 2 == 0 {
            let x = CGFloat(i) * bw + bw * 0.3
            ctx.fill(CGRect(x: x, y: base - h * heights[i] + 14, width: 5, height: 7))
            ctx.fill(CGRect(x: x + 10, y: base - h * heights[i] + 30, width: 5, height: 7))
        }
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: h * 0.72))
        line.addLine(to: CGPoint(x: w * 0.3, y: h * 0.64))
        line.addLine(to: CGPoint(x: w * 0.5, y: h * 0.68))
        line.addLine(to: CGPoint(x: w * 0.72, y: h * 0.52))
        line.addLine(to: CGPoint(x: w, y: h * 0.44))
        line.lineWidth = 4; line.lineCapStyle = .round; line.lineJoinStyle = .round
        UIColor(hex: 0x4ADE80).setStroke(); line.stroke()
    }

    // MARK: Gold bars
    private func drawGoldBars(_ ctx: CGContext, _ r: CGRect) {
        let w = r.width, h = r.height
        UIColor(hex: 0xFFD700).withAlphaComponent(0.12).setFill()
        ctx.fillEllipse(in: CGRect(x: w * 0.08, y: h * 0.04, width: w * 0.5, height: w * 0.5))

        let bw = w * 0.26, bh = h * 0.12, cx = w * 0.5
        func bar(_ x: CGFloat, _ y: CGFloat) {
            UIColor(hex: 0xFFC107).setFill()
            UIBezierPath(roundedRect: CGRect(x: x, y: y, width: bw, height: bh), cornerRadius: 4).fill()
            UIColor(hex: 0xFFE082).setFill()
            UIBezierPath(roundedRect: CGRect(x: x, y: y, width: bw, height: bh * 0.34), cornerRadius: 4).fill()
        }
        bar(cx - bw - 6, h * 0.58)
        bar(cx + 6, h * 0.58)
        bar(cx - bw / 2, h * 0.58 - bh - 6)

        star(w * 0.74, h * 0.18, 9, UIColor.white.withAlphaComponent(0.9))
        star(w * 0.22, h * 0.30, 6, UIColor.white.withAlphaComponent(0.7))
        star(w * 0.85, h * 0.40, 5, UIColor.white.withAlphaComponent(0.6))
    }

    // MARK: Candlestick chart
    private func drawCandles(_ ctx: CGContext, _ r: CGRect) {
        let w = r.width, h = r.height
        let n = 6
        let slot = w / CGFloat(n)
        let bodyFracs: [CGFloat] = [0.18, 0.26, 0.15, 0.30, 0.22, 0.34]
        for i in 0..<n {
            let cx = slot * (CGFloat(i) + 0.5)
            let bull = i % 3 != 2
            let col = bull ? UIColor(hex: 0x4ADE80) : UIColor(hex: 0xF87171)
            let bodyH = h * bodyFracs[i]
            let bodyY = h * 0.62 - bodyH * 0.5 - CGFloat(i) * h * 0.018
            col.setStroke()
            let wick = UIBezierPath()
            wick.move(to: CGPoint(x: cx, y: bodyY - 12))
            wick.addLine(to: CGPoint(x: cx, y: bodyY + bodyH + 12))
            wick.lineWidth = 3; wick.stroke()
            col.setFill()
            UIBezierPath(roundedRect: CGRect(x: cx - 8, y: bodyY, width: 16, height: bodyH), cornerRadius: 3).fill()
        }
    }

    // MARK: Classical columns (Fed / bank)
    private func drawColumns(_ ctx: CGContext, _ r: CGRect) {
        let w = r.width, h = r.height
        let top = h * 0.30, base = h * 0.74
        let left = w * 0.16, right = w * 0.84, bw = right - left
        UIColor(hex: 0xE8EDF2).withAlphaComponent(0.85).setFill()

        let tri = UIBezierPath()
        tri.move(to: CGPoint(x: left - 12, y: top))
        tri.addLine(to: CGPoint(x: w * 0.5, y: top - h * 0.12))
        tri.addLine(to: CGPoint(x: right + 12, y: top))
        tri.close(); tri.fill()

        ctx.fill(CGRect(x: left - 12, y: top, width: bw + 24, height: h * 0.05))
        let cols = 5
        let gap = bw / CGFloat(cols)
        for i in 0..<cols {
            ctx.fill(CGRect(x: left + gap * CGFloat(i) + gap * 0.2, y: top + h * 0.06,
                            width: gap * 0.4, height: base - (top + h * 0.06)))
        }
        ctx.fill(CGRect(x: left - 18, y: base, width: bw + 36, height: h * 0.045))
    }

    // MARK: Oil barrel + đường giá giảm
    private func drawBarrel(_ ctx: CGContext, _ r: CGRect) {
        let w = r.width, h = r.height
        let bw = w * 0.32, bh = h * 0.34
        let x = w * 0.5 - bw / 2, y = h * 0.30
        UIColor(hex: 0x1E1E1E).withAlphaComponent(0.9).setFill()
        UIBezierPath(roundedRect: CGRect(x: x, y: y, width: bw, height: bh), cornerRadius: 14).fill()
        UIColor(hex: 0x5A5A5A).setFill()
        ctx.fill(CGRect(x: x, y: y + bh * 0.22, width: bw, height: 4))
        ctx.fill(CGRect(x: x, y: y + bh * 0.62, width: bw, height: 4))
        UIColor(hex: 0xF4A259).withAlphaComponent(0.9).setFill()
        ctx.fillEllipse(in: CGRect(x: x + bw / 2 - 7, y: y + bh * 0.38, width: 14, height: 18))

        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: h * 0.46))
        line.addLine(to: CGPoint(x: w * 0.3, y: h * 0.54))
        line.addLine(to: CGPoint(x: w * 0.6, y: h * 0.5))
        line.addLine(to: CGPoint(x: w, y: h * 0.66))
        line.lineWidth = 4; line.lineCapStyle = .round; line.lineJoinStyle = .round
        UIColor(hex: 0xF87171).setStroke(); line.stroke()
    }

    // MARK: Coin (crypto / tỷ giá)
    private func drawCoin(_ ctx: CGContext, _ r: CGRect, glyph: String, color: UIColor) {
        let w = r.width, h = r.height
        let radius = min(w, h) * 0.2
        let c = CGPoint(x: w * 0.5, y: h * 0.36)
        color.withAlphaComponent(0.16).setFill()
        ctx.fillEllipse(in: CGRect(x: c.x - radius * 1.8, y: c.y - radius * 1.8, width: radius * 3.6, height: radius * 3.6))
        color.setFill()
        ctx.fillEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
        UIColor.white.withAlphaComponent(0.5).setStroke()
        let ring = UIBezierPath(ovalIn: CGRect(x: c.x - radius * 0.78, y: c.y - radius * 0.78,
                                               width: radius * 1.56, height: radius * 1.56))
        ring.lineWidth = 3; ring.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: radius * 1.2, weight: .heavy),
            .foregroundColor: UIColor.white,
        ]
        let s = glyph as NSString
        let size = s.size(withAttributes: attrs)
        s.draw(at: CGPoint(x: c.x - size.width / 2, y: c.y - size.height / 2), withAttributes: attrs)
    }

    // MARK: Helper — ngôi sao 4 cánh
    private func star(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ color: UIColor) {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: cx, y: cy - s))
        p.addLine(to: CGPoint(x: cx + s * 0.28, y: cy - s * 0.28))
        p.addLine(to: CGPoint(x: cx + s, y: cy))
        p.addLine(to: CGPoint(x: cx + s * 0.28, y: cy + s * 0.28))
        p.addLine(to: CGPoint(x: cx, y: cy + s))
        p.addLine(to: CGPoint(x: cx - s * 0.28, y: cy + s * 0.28))
        p.addLine(to: CGPoint(x: cx - s, y: cy))
        p.addLine(to: CGPoint(x: cx - s * 0.28, y: cy - s * 0.28))
        p.close()
        color.setFill(); p.fill()
    }
}
