import UIKit

// MARK: - PollCard
/// Cell trending poll (200x240) trong horizontal scroll của Feed.
final class PollCard: UICollectionViewCell {
    static let reuseId = "PollCard"

    private let assetChip = ChipLabel()
    private let titleLabel = UILabel()
    private let voteBar = VoteBar(height: 6)
    private let votesLabel = UILabel()
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.applyCardStyle()

        titleLabel.font = FeelitFonts.title
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        votesLabel.font = FeelitFonts.caption
        votesLabel.textColor = FeelitColors.textSecondary

        timeLabel.font = FeelitFonts.caption
        timeLabel.textColor = FeelitColors.bullish
        timeLabel.textAlignment = .right

        let bottomRow = UIStackView(arrangedSubviews: [votesLabel, timeLabel])
        bottomRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [assetChip, titleLabel, UIView(), voteBar, bottomRow])
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        // assetChip & các row co theo chiều ngang đầy đủ
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.lg),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.lg),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.lg),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.lg),
            voteBar.widthAnchor.constraint(equalTo: stack.widthAnchor),
            bottomRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    func configure(with poll: FEPoll) {
        assetChip.style(text: poll.asset, textColor: FeelitColors.primary, background: FeelitColors.primarySoft)
        titleLabel.text = poll.title
        votesLabel.text = poll.votesText
        timeLabel.text = "⏳ \(poll.endsIn)"
        voteBar.setYesRatio(CGFloat(poll.yesPercent) / 100, animated: false)
    }

    // Nhấn → scale spring 0.96
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: Motion.duration, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: Motion.velocity) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
}
