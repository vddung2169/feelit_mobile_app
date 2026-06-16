import UIKit

// MARK: - AssetCard
/// Grid 2 cột: logo gradient + ticker + tên + sentiment bar + votes.
final class AssetCard: UICollectionViewCell {
    static let reuseId = "AssetCard"

    private let logo = AvatarView(size: 40, fontSize: 15)
    private let tickerLabel = UILabel()
    private let nameLabel = UILabel()
    private let sentimentBar = VoteBar(height: 6)
    private let votesLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.applyCardStyle(corner: Radius.smallCard)

        tickerLabel.font = FeelitFonts.heading
        tickerLabel.textColor = FeelitColors.primary
        nameLabel.font = FeelitFonts.caption
        nameLabel.textColor = FeelitColors.textSecondary
        nameLabel.numberOfLines = 1
        votesLabel.font = FeelitFonts.micro
        votesLabel.textColor = FeelitColors.textTertiary

        let stack = UIStackView(arrangedSubviews: [logo, tickerLabel, nameLabel, sentimentBar, votesLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.sm
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.md),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.md),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.md),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.md),
            sentimentBar.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with asset: FEAsset) {
        logo.configure(username: asset.ticker)
        tickerLabel.text = "#\(asset.ticker)"
        nameLabel.text = asset.name
        votesLabel.text = "\(asset.votes) votes"
        sentimentBar.setYesRatio(CGFloat(asset.bullish) / 100, animated: false)
    }
}

// MARK: - InvestorCard
/// 120x160 horizontal: avatar + username + accuracy badge + streak.
final class InvestorCard: UICollectionViewCell {
    static let reuseId = "InvestorCard"

    private let avatar = AvatarView(size: 56, fontSize: 22)
    private let usernameLabel = UILabel()
    private let accuracyChip = ChipLabel()
    private let streakLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.applyCardStyle(corner: Radius.smallCard)

        usernameLabel.font = FeelitFonts.title
        usernameLabel.textColor = FeelitColors.textPrimary
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.7
        streakLabel.font = FeelitFonts.caption
        streakLabel.textColor = FeelitColors.gold

        let stack = UIStackView(arrangedSubviews: [avatar, usernameLabel, accuracyChip, streakLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.sm),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.sm),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with inv: FEInvestor) {
        avatar.configure(username: inv.username)
        usernameLabel.text = inv.username
        accuracyChip.style(text: "\(inv.accuracy)% ✓", textColor: FeelitColors.bullish, background: FeelitColors.bullishSoft)
        streakLabel.text = "🔥 \(inv.streak)"
    }
}

// MARK: - CategoryChipCell
final class CategoryChipCell: UICollectionViewCell {
    static let reuseId = "CategoryChipCell"
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        label.font = FeelitFonts.body
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.lg),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.lg),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, selected: Bool) {
        label.text = title
        contentView.backgroundColor = selected ? FeelitColors.primary : FeelitColors.surfaceElevated
        label.textColor = selected ? .white : FeelitColors.textSecondary
    }
}
