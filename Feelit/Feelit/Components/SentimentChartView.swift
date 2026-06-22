import UIKit

// MARK: - SentimentChartView
/// Area chart realtime kiểu Kalshi (prediction market) — thuần CoreGraphics, không dependency.
/// Đường cong Catmull-Rom mượt + fill gradient + live dot nhấp nháy + crosshair khi chạm.
final class SentimentChartView: UIView {

    // MARK: - Public API

    /// Set toàn bộ data lần đầu (từ REST). value: % 0...100.
    func setInitialData(_ points: [Double]) {
        dataPoints = Array(points.suffix(maxVisiblePoints))
        rebuild(animated: false)
    }

    /// Thêm 1 điểm realtime (socket). Tự animate + scroll + update live dot.
    func appendDataPoint(_ value: Double) {
        dataPoints.append(value.clamped(0, 100))
        if dataPoints.count > maxVisiblePoints { dataPoints.removeFirst() }
        rebuild(animated: true)
    }

    var isLoading: Bool = false { didSet { updateLoadingState() } }

    // MARK: - Config
    private let maxVisiblePoints = 60
    private let lineColor = FeelitColors.primary
    private let animationDuration: CFTimeInterval = 0.3
    private let insets = UIEdgeInsets(top: 16, left: 36, bottom: 8, right: 16)

    // MARK: - State
    private var dataPoints: [Double] = []
    private var hideCrosshairWork: DispatchWorkItem?

    // MARK: - Layers
    private let gridLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let fillMaskLayer = CAShapeLayer()
    private let lineLayer = CAShapeLayer()
    private let crosshairLayer = CAShapeLayer()

    // MARK: - Subviews
    private let liveDot = UIView()
    private let crosshairDot = UIView()
    private let tooltipContainer = UIView()
    private let tooltipLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var yLabels: [UILabel] = []

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = FeelitColors.surface
        layer.cornerRadius = 20
        clipsToBounds = true

        // Grid
        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.04).cgColor   // #FFFFFF0A
        gridLayer.lineWidth = 1
        gridLayer.fillColor = nil
        layer.addSublayer(gridLayer)

        // Gradient fill (mask theo area path)
        gradientLayer.colors = [lineColor.withAlphaComponent(0.4).cgColor,
                                lineColor.withAlphaComponent(0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        fillMaskLayer.fillColor = UIColor.black.cgColor
        gradientLayer.mask = fillMaskLayer
        layer.addSublayer(gradientLayer)

        // Line
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.lineWidth = 2.5
        lineLayer.fillColor = nil
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        layer.addSublayer(lineLayer)

        // Crosshair line
        crosshairLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor  // #FFFFFF30
        crosshairLayer.lineWidth = 1
        crosshairLayer.fillColor = nil
        crosshairLayer.isHidden = true
        layer.addSublayer(crosshairLayer)

        // Live dot + pulse
        liveDot.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        liveDot.layer.cornerRadius = 5
        liveDot.backgroundColor = lineColor
        liveDot.isHidden = true
        addSubview(liveDot)
        addPulse()

        // Crosshair dot
        crosshairDot.frame = CGRect(x: 0, y: 0, width: 8, height: 8)
        crosshairDot.layer.cornerRadius = 4
        crosshairDot.backgroundColor = lineColor
        crosshairDot.layer.borderColor = UIColor.white.cgColor
        crosshairDot.layer.borderWidth = 2
        crosshairDot.isHidden = true
        addSubview(crosshairDot)

        // Tooltip
        tooltipContainer.backgroundColor = FeelitColors.surfaceElevated
        tooltipContainer.layer.cornerRadius = 8
        tooltipContainer.isHidden = true
        tooltipLabel.font = .systemFont(ofSize: 13, weight: .bold)
        tooltipLabel.textColor = FeelitColors.textPrimary
        tooltipLabel.textAlignment = .center
        tooltipContainer.addSubview(tooltipLabel)
        addSubview(tooltipContainer)

        // Y labels (top → bottom)
        ["100%", "67%", "33%", "0%"].forEach { t in
            let l = UILabel()
            l.text = t
            l.font = .systemFont(ofSize: 10)
            l.textColor = FeelitColors.textTertiary
            l.textAlignment = .right
            addSubview(l)
            yLabels.append(l)
        }

        // Spinner
        spinner.color = FeelitColors.textSecondary
        spinner.hidesWhenStopped = true
        addSubview(spinner)

        // Touch → crosshair
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handleTouch(_:)))
        press.minimumPressDuration = 0
        addGestureRecognizer(press)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        fillMaskLayer.frame = bounds
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
        rebuild(animated: false)
    }

    private var plotRect: CGRect {
        CGRect(x: insets.left, y: insets.top,
               width: bounds.width - insets.left - insets.right,
               height: bounds.height - insets.top - insets.bottom)
    }

    private func point(at index: Int) -> CGPoint {
        let r = plotRect
        let n = dataPoints.count
        let x = n <= 1 ? r.maxX : r.minX + r.width * CGFloat(index) / CGFloat(n - 1)
        let y = r.maxY - r.height * CGFloat(dataPoints[index] / 100)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Build paths
    private func rebuild(animated: Bool) {
        guard bounds.width > 1, !isLoading else { return }
        layoutGridAndLabels()

        let hasLine = dataPoints.count > 1
        lineLayer.isHidden = !hasLine
        gradientLayer.isHidden = dataPoints.isEmpty
        liveDot.isHidden = dataPoints.isEmpty

        let line = catmullRomPath()
        let fill = dataPoints.isEmpty ? UIBezierPath() : fillPath(from: line)

        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        } else {
            CATransaction.setDisableActions(true)
        }
        lineLayer.path = line.cgPath
        fillMaskLayer.path = fill.cgPath
        CATransaction.commit()

        updateLiveDot(animated: animated)
    }

    /// Catmull-Rom → Bezier cho đường cong mượt.
    private func catmullRomPath() -> UIBezierPath {
        let path = UIBezierPath()
        guard dataPoints.count > 1 else { return path }
        let pts = (0..<dataPoints.count).map { point(at: $0) }
        path.move(to: pts[0])
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = pts[min(i + 2, pts.count - 1)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }
        return path
    }

    private func fillPath(from line: UIBezierPath) -> UIBezierPath {
        let fill = line.copy() as! UIBezierPath
        let r = plotRect
        fill.addLine(to: CGPoint(x: point(at: dataPoints.count - 1).x, y: r.maxY))
        fill.addLine(to: CGPoint(x: point(at: 0).x, y: r.maxY))
        fill.close()
        return fill
    }

    private func layoutGridAndLabels() {
        let r = plotRect
        let fracs: [CGFloat] = [0, 1.0 / 3, 2.0 / 3, 1]
        let grid = UIBezierPath()
        for f in fracs {
            let y = r.maxY - r.height * f
            grid.move(to: CGPoint(x: r.minX, y: y))
            grid.addLine(to: CGPoint(x: r.maxX, y: y))
        }
        gridLayer.path = grid.cgPath

        let labelFracs: [CGFloat] = [1, 2.0 / 3, 1.0 / 3, 0]   // 100,67,33,0
        for (i, l) in yLabels.enumerated() {
            let y = r.maxY - r.height * labelFracs[i]
            l.frame = CGRect(x: 4, y: y - 6, width: insets.left - 8, height: 12)
        }
    }

    // MARK: - Live dot
    private func addPulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.5
        pulse.duration = 1.2
        pulse.repeatCount = .infinity
        pulse.autoreverses = true
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        liveDot.layer.add(pulse, forKey: "pulse")
    }

    private func updateLiveDot(animated: Bool) {
        guard let last = dataPoints.indices.last else { return }
        let p = point(at: last)
        if animated {
            UIView.animate(withDuration: animationDuration) { self.liveDot.center = p }
        } else {
            liveDot.center = p
        }
    }

    // MARK: - Crosshair
    @objc private func handleTouch(_ g: UILongPressGestureRecognizer) {
        guard !dataPoints.isEmpty, !isLoading else { return }
        switch g.state {
        case .began, .changed:
            hideCrosshairWork?.cancel()
            showCrosshair(at: g.location(in: self))
        case .ended, .cancelled, .failed:
            scheduleHideCrosshair()
        default: break
        }
    }

    private func showCrosshair(at loc: CGPoint) {
        let r = plotRect
        let n = dataPoints.count
        let idx: Int = n <= 1 ? 0 : max(0, min(n - 1, Int((((loc.x - r.minX) / r.width) * CGFloat(n - 1)).rounded())))
        let p = point(at: idx)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: p.x, y: r.minY))
        path.addLine(to: CGPoint(x: p.x, y: r.maxY))
        CATransaction.begin(); CATransaction.setDisableActions(true)
        crosshairLayer.path = path.cgPath
        CATransaction.commit()
        crosshairLayer.isHidden = false

        crosshairDot.center = p
        crosshairDot.isHidden = false

        tooltipLabel.text = "\(Int(dataPoints[idx].rounded()))%"
        layoutTooltip(around: p)
        tooltipContainer.isHidden = false
    }

    private func layoutTooltip(around p: CGPoint) {
        tooltipLabel.sizeToFit()
        let w = tooltipLabel.bounds.width + 20   // padding 10 ngang
        let h = tooltipLabel.bounds.height + 12   // padding 6 dọc
        var x = p.x - w / 2
        x = max(insets.left, min(bounds.width - insets.right - w, x))
        let y = max(insets.top, p.y - h - 10)
        tooltipContainer.frame = CGRect(x: x, y: y, width: w, height: h)
        tooltipLabel.frame = tooltipContainer.bounds
    }

    private func scheduleHideCrosshair() {
        let work = DispatchWorkItem { [weak self] in self?.hideCrosshair() }
        hideCrosshairWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    private func hideCrosshair() {
        crosshairLayer.isHidden = true
        crosshairDot.isHidden = true
        tooltipContainer.isHidden = true
    }

    // MARK: - Loading
    private func updateLoadingState() {
        if isLoading {
            spinner.startAnimating()
            [lineLayer, gradientLayer, gridLayer, crosshairLayer].forEach { $0.isHidden = true }
            liveDot.isHidden = true
            hideCrosshair()
        } else {
            spinner.stopAnimating()
            gridLayer.isHidden = false
            rebuild(animated: false)
        }
    }
}

// MARK: - Helper
private extension Double {
    func clamped(_ lo: Double, _ hi: Double) -> Double { Swift.max(lo, Swift.min(hi, self)) }
}
