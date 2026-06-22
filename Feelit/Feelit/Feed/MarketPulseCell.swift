import UIKit

// MARK: - MarketPulseCell
/// Section 1 của Feed: card gradient (primary → bearish) hiển thị % bullish toàn thị trường.
final class MarketPulseCell: UICollectionViewCell {
    static let reuseId = "MarketPulseCell"

    private let gradientCard = GradientView(
        colors: [FeelitColors.primary.cgColor, FeelitColors.bearish.cgColor],
        start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1, y: 1))

    private let kicker = UILabel()
    private let bigNumber = UILabel()
    private let subtitle = UILabel()
    private let voteBar = VoteBar(height: 28)
    private let yesLabel = UILabel()
    private let noLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        gradientCard.layer.cornerRadius = Radius.largeCard
        gradientCard.clipsToBounds = true
        gradientCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientCard)

        kicker.setMicro("MARKET PULSE", color: UIColor.white.withAlphaComponent(0.85))

        bigNumber.font = FeelitFonts.display
        bigNumber.textColor = .white

        subtitle.font = FeelitFonts.caption
        subtitle.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitle.numberOfLines = 0

        yesLabel.font = FeelitFonts.micro
        yesLabel.textColor = .white
        noLabel.font = FeelitFonts.micro
        noLabel.textColor = .white
        noLabel.textAlignment = .right

        let labelRow = UIStackView(arrangedSubviews: [yesLabel, noLabel])
        labelRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [kicker, bigNumber, subtitle, voteBar, labelRow])
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        stack.setCustomSpacing(Spacing.lg, after: subtitle)
        stack.setCustomSpacing(Spacing.xs, after: voteBar)
        stack.translatesAutoresizingMaskIntoConstraints = false
        gradientCard.addSubview(stack)

        NSLayoutConstraint.activate([
            gradientCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stack.topAnchor.constraint(equalTo: gradientCard.topAnchor, constant: Spacing.xl),
            stack.leadingAnchor.constraint(equalTo: gradientCard.leadingAnchor, constant: Spacing.xl),
            stack.trailingAnchor.constraint(equalTo: gradientCard.trailingAnchor, constant: -Spacing.xl),
            stack.bottomAnchor.constraint(equalTo: gradientCard.bottomAnchor, constant: -Spacing.xl),
        ])
    }

    func configure(bullishPercent: Int, voters: Int) {
        bigNumber.text = "\(bullishPercent)% BULLISH"
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: voters), number: .decimal)
        subtitle.text = "\(formatted) nhà đầu tư đã vote hôm nay"
        yesLabel.text = "TĂNG \(bullishPercent)%"
        noLabel.text = "GIẢM \(100 - bullishPercent)%"
        voteBar.setYesRatio(CGFloat(bullishPercent) / 100, animated: false)
        // Animate sau 1 nhịp để thấy chuyển động.
        DispatchQueue.main.async {
            self.voteBar.setYesRatio(CGFloat(bullishPercent) / 100, animated: true)
        }
    }
}
