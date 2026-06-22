import UIKit

// MARK: - NotificationCell
/// 1 dòng thông báo: chấm chưa đọc + title + body + thời gian.
final class NotificationCell: UITableViewCell {
    static let reuseId = "NotificationCell"

    private let unreadDot = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
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
        unreadDot.backgroundColor = FeelitColors.primary
        unreadDot.layer.cornerRadius = 4
        unreadDot.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = FeelitFonts.title
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.numberOfLines = 1

        bodyLabel.font = FeelitFonts.caption
        bodyLabel.textColor = FeelitColors.textSecondary
        bodyLabel.numberOfLines = 2

        timeLabel.font = FeelitFonts.micro
        timeLabel.textColor = FeelitColors.textTertiary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, timeLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(unreadDot)
        contentView.addSubview(textStack)
        NSLayoutConstraint.activate([
            unreadDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            unreadDot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),

            textStack.leadingAnchor.constraint(equalTo: unreadDot.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with n: AppNotification) {
        titleLabel.text = n.title
        bodyLabel.text = n.body
        timeLabel.text = n.formattedTime
        unreadDot.isHidden = n.isRead
    }
}
