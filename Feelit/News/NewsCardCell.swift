import UIKit

// MARK: - Gradient + decorative chart background
final class CardBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let overlayLayer = CAGradientLayer()   // tối dần xuống đáy cho dễ đọc chữ
    private let chartLayer = CAShapeLayer()
    private let candleLayer = CAShapeLayer()
    private var showsChart = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientLayer)

        // Đường giá tăng
        chartLayer.fillColor = nil
        chartLayer.strokeColor = UIColor(hex: "#4ADE80").cgColor
        chartLayer.lineWidth = 4
        chartLayer.lineCap = .round
        chartLayer.lineJoin = .round
        chartLayer.opacity = 0.85
        layer.addSublayer(chartLayer)

        candleLayer.fillColor = UIColor(hex: "#4ADE80").withAlphaComponent(0.9).cgColor
        layer.addSublayer(candleLayer)

        // Overlay tối ở đáy
        overlayLayer.colors = [
            UIColor.black.withAlphaComponent(0.30).cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.88).cgColor,
        ]
        overlayLayer.locations = [0, 0.30, 0.66]
        layer.addSublayer(overlayLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(gradient: [UIColor], showsChart: Bool) {
        gradientLayer.colors = gradient.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.4, y: 1)
        self.showsChart = showsChart
        chartLayer.isHidden = !showsChart
        candleLayer.isHidden = !showsChart
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        overlayLayer.frame = bounds
        if showsChart { drawChart() }
        CATransaction.commit()
    }

    private func drawChart() {
        let w = bounds.width, h = bounds.height
        guard w > 0, h > 0 else { return }
        // Đường giá đi lên ở khoảng giữa thẻ
        let xs: [CGFloat] = [0, 0.16, 0.33, 0.5, 0.66, 0.82, 1]
        let ys: [CGFloat] = [0.62, 0.55, 0.58, 0.46, 0.42, 0.48, 0.34]
        let path = UIBezierPath()
        for (i, fx) in xs.enumerated() {
            let p = CGPoint(x: fx * w, y: ys[i] * h)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        chartLayer.path = path.cgPath

        // Vài cây nến
        let candles = UIBezierPath()
        func candle(_ fx: CGFloat, _ topF: CGFloat, _ botF: CGFloat) {
            let cx = fx * w
            let rect = CGRect(x: cx - 7, y: topF * h, width: 14, height: (botF - topF) * h)
            candles.append(UIBezierPath(roundedRect: rect, cornerRadius: 4))
            let wick = UIBezierPath(rect: CGRect(x: cx - 1.5, y: (topF - 0.03) * h,
                                                 width: 3, height: (botF - topF + 0.06) * h))
            candles.append(wick)
        }
        candle(0.16, 0.55, 0.66)
        candle(0.5, 0.46, 0.58)
        candle(0.82, 0.50, 0.60)
        candleLayer.path = candles.cgPath
        candleLayer.opacity = 0.55
    }
}

// MARK: - Một lựa chọn vote (ẩn % cho tới khi vote)
final class CardOptionView: UIView {

    private let fillView = UIView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private var fillZero: NSLayoutConstraint!
    private var fillFull: NSLayoutConstraint!

    private let option: NewsOption
    private let layout: NewsCard.Layout
    var onTap: (() -> Void)?

    init(option: NewsOption, layout: NewsCard.Layout) {
        self.option = option
        self.layout = layout
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.14)
        layer.cornerRadius = layout == .binary ? 24 : 22
        clipsToBounds = true

        fillView.backgroundColor = option.tint
        fillView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fillView)
        let frac = max(0.02, CGFloat(option.percent) / 100)
        fillZero = fillView.widthAnchor.constraint(equalToConstant: 0)
        fillFull = fillView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: frac)
        NSLayoutConstraint.activate([
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fillZero,  // mặc định chưa vote: fill = 0
        ])

        layout == .binary ? buildBinary() : buildMultiple()

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.08, animations: { self.transform = .init(scaleX: 0.96, y: 0.96) }) { _ in
            UIView.animate(withDuration: 0.08) { self.transform = .identity }
        }
        onTap?()
    }

    private func buildBinary() {
        titleLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.text = option.title

        detailLabel.font = .systemFont(ofSize: 11, weight: .bold)
        detailLabel.textColor = UIColor(white: 1, alpha: 0.6)
        detailLabel.text = "Chạm để chọn"

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func buildMultiple() {
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.text = option.title

        detailLabel.font = .systemFont(ofSize: 14, weight: .heavy)
        detailLabel.textColor = UIColor(white: 1, alpha: 0.5)
        detailLabel.text = "Chọn"

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(detailLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 17),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -17),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    /// Cập nhật trạng thái hiển thị. `revealed` = đã vote (hiện %, fill bar).
    func setRevealed(_ revealed: Bool, chosen: Bool, animated: Bool) {
        // Viền: nổi bật lựa chọn người dùng chọn, hoặc lựa chọn dẫn đầu sau khi reveal.
        let showBorder = revealed && (chosen || option.highlighted)
        layer.borderWidth = showBorder ? 1.5 : 0
        layer.borderColor = (chosen ? UIColor.white : UIColor(white: 1, alpha: 0.55)).cgColor

        let pct = option.detail ?? "\(option.percent)%"
        if layout == .binary {
            detailLabel.text = revealed ? pct : "Chạm để chọn"
            detailLabel.textColor = UIColor(white: 1, alpha: revealed ? 0.75 : 0.6)
        } else {
            detailLabel.text = revealed ? pct : "Chọn"
            detailLabel.textColor = revealed
                ? (option.highlighted ? UIColor(hex: "#FFD66B") : UIColor(white: 1, alpha: 0.78))
                : UIColor(white: 1, alpha: 0.5)
        }

        fillZero.isActive = !revealed
        fillFull.isActive = revealed

        let work = { self.layoutIfNeeded() }
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: work)
        } else {
            work()
        }
    }
}

// MARK: - Flash card cell
final class NewsCardCell: UICollectionViewCell {
    static let id = "NewsCardCell"

    private let cardView = UIView()
    private let bg = CardBackgroundView()

    // Top bar
    private let badge = UILabel()
    private let headlineBox = UIView()
    private let headlineValue = UILabel()
    private let headlineLabel = UILabel()

    // Bottom block
    private let authorName = UILabel()
    private let verifiedMark = UILabel()
    private let closingLabel = UILabel()
    private let contextLabel = UILabel()
    private let questionLabel = UILabel()
    private let optionsStack = UIStackView()
    private let footerLabel = UILabel()

    // Vote state
    private var optionViews: [CardOptionView] = []
    private var votedIndex: Int?
    private var hasHeadline = false
    private var onVote: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        setupTopBar()
        setupBottom()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Card container
    private func setupCard() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 40
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)

        bg.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bg)

        let g = contentView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: g.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),

            bg.topAnchor.constraint(equalTo: cardView.topAnchor),
            bg.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
        ])
    }

    // MARK: Top bar (badge + headline box)
    private func setupTopBar() {
        badge.font = .systemFont(ofSize: 10, weight: .heavy)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        headlineBox.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        headlineBox.layer.cornerRadius = 18
        headlineBox.clipsToBounds = true
        headlineBox.translatesAutoresizingMaskIntoConstraints = false

        headlineValue.font = .systemFont(ofSize: 30, weight: .heavy)
        headlineLabel.font = .systemFont(ofSize: 8, weight: .heavy)
        headlineLabel.textColor = UIColor(white: 1, alpha: 0.65)
        let hStack = UIStackView(arrangedSubviews: [headlineValue, headlineLabel])
        hStack.axis = .vertical
        hStack.alignment = .trailing
        hStack.spacing = 2
        hStack.translatesAutoresizingMaskIntoConstraints = false
        headlineBox.addSubview(hStack)

        cardView.addSubview(badge)
        cardView.addSubview(headlineBox)

        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            badge.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            badge.heightAnchor.constraint(equalToConstant: 24),

            headlineBox.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            headlineBox.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            hStack.topAnchor.constraint(equalTo: headlineBox.topAnchor, constant: 9),
            hStack.bottomAnchor.constraint(equalTo: headlineBox.bottomAnchor, constant: -9),
            hStack.leadingAnchor.constraint(equalTo: headlineBox.leadingAnchor, constant: 14),
            hStack.trailingAnchor.constraint(equalTo: headlineBox.trailingAnchor, constant: -14),
        ])
    }

    // MARK: Bottom content block
    private func setupBottom() {
        // author row
        let logo = UIView()
        logo.backgroundColor = .white
        logo.layer.cornerRadius = 8
        logo.translatesAutoresizingMaskIntoConstraints = false
        let chevron = UILabel()
        chevron.text = "∨"
        chevron.font = .systemFont(ofSize: 13, weight: .heavy)
        chevron.textColor = .black
        chevron.textAlignment = .center
        chevron.translatesAutoresizingMaskIntoConstraints = false
        logo.addSubview(chevron)

        authorName.font = .systemFont(ofSize: 13, weight: .heavy)
        authorName.textColor = .white
        verifiedMark.text = "✓"
        verifiedMark.font = .systemFont(ofSize: 11, weight: .heavy)
        verifiedMark.textColor = UIColor(hex: "#4ADE80")
        closingLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        closingLabel.textColor = UIColor(white: 1, alpha: 0.55)
        closingLabel.textAlignment = .right
        closingLabel.setContentHuggingPriority(.required, for: .horizontal)

        let authorRow = UIStackView(arrangedSubviews: [logo, authorName, verifiedMark, closingLabel])
        authorRow.axis = .horizontal
        authorRow.alignment = .center
        authorRow.spacing = 7

        contextLabel.font = .systemFont(ofSize: 12, weight: .medium)
        contextLabel.textColor = UIColor(white: 1, alpha: 0.65)
        contextLabel.numberOfLines = 2

        questionLabel.font = .systemFont(ofSize: 22, weight: .heavy)
        questionLabel.numberOfLines = 0
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.8

        optionsStack.axis = .horizontal
        optionsStack.distribution = .fillEqually
        optionsStack.spacing = 10

        footerLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        footerLabel.textColor = UIColor(white: 1, alpha: 0.5)
        footerLabel.textAlignment = .center

        let block = UIStackView(arrangedSubviews: [
            authorRow, contextLabel, questionLabel, optionsStack, footerLabel,
        ])
        block.axis = .vertical
        block.spacing = 12
        block.setCustomSpacing(6, after: authorRow)
        block.setCustomSpacing(16, after: questionLabel)
        block.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(block)

        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 26),
            logo.heightAnchor.constraint(equalToConstant: 26),
            chevron.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
            chevron.centerYAnchor.constraint(equalTo: logo.centerYAnchor),

            block.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 22),
            block.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -22),
            block.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -26),
        ])
    }

    // MARK: Configure
    /// `selectedIndex` = lựa chọn đã vote (nil nếu chưa vote → ẩn %).
    func configure(with card: NewsCard, selectedIndex: Int?, onVote: @escaping (Int) -> Void) {
        self.onVote = onVote
        self.votedIndex = selectedIndex

        bg.configure(gradient: card.gradient, showsChart: card.showsChart)

        badge.text = "  \(card.badge)  "
        badge.backgroundColor = card.badgeColor

        hasHeadline = (card.headline != nil)
        if let h = card.headline {
            headlineValue.text = h.value
            headlineValue.textColor = h.color
            headlineLabel.text = h.label
        }

        authorName.text = card.author
        verifiedMark.isHidden = !card.verified
        closingLabel.text = card.closing

        contextLabel.text = card.context
        contextLabel.isHidden = (card.context == nil)

        questionLabel.text = card.question
        questionLabel.textColor = card.questionColor

        footerLabel.text = card.footer

        // Build options
        optionViews.forEach { $0.removeFromSuperview() }
        optionViews = []
        optionsStack.axis = (card.layout == .binary) ? .horizontal : .vertical
        optionsStack.distribution = (card.layout == .binary) ? .fillEqually : .fill
        optionsStack.spacing = (card.layout == .binary) ? 10 : 9
        for (i, opt) in card.options.enumerated() {
            let v = CardOptionView(option: opt, layout: card.layout)
            v.onTap = { [weak self] in self?.handleVote(i) }
            optionsStack.addArrangedSubview(v)
            optionViews.append(v)
        }

        applyRevealState(animated: false)
    }

    private func handleVote(_ index: Int) {
        guard votedIndex == nil else { return }   // chỉ vote 1 lần
        votedIndex = index
        applyRevealState(animated: true)
        onVote?(index)
    }

    /// Hiện/ẩn % theo trạng thái vote.
    private func applyRevealState(animated: Bool) {
        let voted = (votedIndex != nil)
        for (i, v) in optionViews.enumerated() {
            v.setRevealed(voted, chosen: votedIndex == i, animated: animated)
        }

        // Box % góc phải chỉ hiện sau khi vote.
        let showHeadline = voted && hasHeadline
        if animated && showHeadline {
            headlineBox.alpha = 0
            headlineBox.isHidden = false
            UIView.animate(withDuration: 0.3) { self.headlineBox.alpha = 1 }
        } else {
            headlineBox.isHidden = !showHeadline
            headlineBox.alpha = 1
        }
    }
}
