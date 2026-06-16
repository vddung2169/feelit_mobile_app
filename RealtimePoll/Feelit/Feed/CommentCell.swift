import UIKit

// MARK: - CommentCell
/// 1 dòng bình luận: [Avatar 36] [Bubble card] [Time].
final class CommentCell: UITableViewCell {
    static let reuseId = "CommentCell"

    private let avatar = AvatarView(size: 36, fontSize: 14)
    private let bubble = UIView()
    private let usernameLabel = UILabel()
    private let contentLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        bubble.backgroundColor = FeelitColors.surfaceElevated
        bubble.layer.cornerRadius = 16
        bubble.translatesAutoresizingMaskIntoConstraints = false

        usernameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        usernameLabel.textColor = FeelitColors.primary

        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentLabel.textColor = FeelitColors.textPrimary
        contentLabel.numberOfLines = 0

        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = FeelitColors.textTertiary
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [usernameLabel, contentLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(textStack)

        contentView.addSubview(avatar)
        contentView.addSubview(bubble)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),

            bubble.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 8),
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            textStack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
            textStack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -10),

            timeLabel.leadingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: 6),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor),
        ])
    }

    func configure(with comment: Comment, groupedWithPrevious: Bool) {
        avatar.configure(username: comment.username)
        avatar.isHidden = groupedWithPrevious
        usernameLabel.text = comment.username
        usernameLabel.isHidden = groupedWithPrevious
        contentLabel.text = comment.content
        timeLabel.text = comment.formattedTime

        // Comment đầu của user → bo top-left nhỏ (4px), còn lại đồng nhất 16px.
        if groupedWithPrevious {
            bubble.layer.cornerRadius = 16
            bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            bubble.layer.cornerRadius = 16
            bubble.layer.maskedCorners = [.layerMaxXMinYCorner,
                                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
}
