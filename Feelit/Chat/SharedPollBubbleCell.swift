import UIKit

// MARK: - SharedPollBubbleCell
/// Bubble dạng "card" cho 1 poll được share vào chat (giống preview share của FB).
/// Bấm vào card → callback `onTap` để route sang màn hình poll.
final class SharedPollBubbleCell: UITableViewCell {

    static let reuseId = "SharedPollBubbleCell"

    /// Gọi khi user bấm vào card. Truyền pollId để VC tự route.
    var onTap: ((String) -> Void)?
    private var pollId: String?

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.cgColor
        v.backgroundColor = .secondarySystemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.text = "📊"
        l.font = .systemFont(ofSize: 28)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let kickerLabel: UILabel = {
        let l = UILabel()
        l.text = "POLL"
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .systemBlue
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "Nhấn để xem poll →"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Constraint động đổi alignment trái/phải
    private var cardLeading: NSLayoutConstraint!
    private var cardTrailing: NSLayoutConstraint!
    private var timeLeading: NSLayoutConstraint!
    private var timeTrailing: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        cardView.layer.borderColor = UIColor.separator.cgColor
    }

    private func setupLayout() {
        contentView.addSubview(cardView)
        contentView.addSubview(timeLabel)

        let textStack = UIStackView(arrangedSubviews: [kickerLabel, titleLabel, hintLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(iconLabel)
        cardView.addSubview(textStack)

        cardLeading  = cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        cardTrailing = cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        timeLeading  = timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 4)
        timeTrailing = timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -4)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),

            iconLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            iconLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            textStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            timeLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 2),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func cardTapped() {
        guard let pollId = pollId else { return }
        onTap?(pollId)
    }

    func configure(with message: Message, shared: SharedPoll) {
        pollId = shared.pollId
        titleLabel.text = shared.title
        timeLabel.text = message.formattedTime

        // Card align theo người gửi giống bubble text.
        if message.isSentByMe {
            cardLeading.isActive = false
            cardTrailing.isActive = true
            timeLeading.isActive = false
            timeTrailing.isActive = true
        } else {
            cardTrailing.isActive = false
            cardLeading.isActive = true
            timeTrailing.isActive = false
            timeLeading.isActive = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        pollId = nil
    }
}
