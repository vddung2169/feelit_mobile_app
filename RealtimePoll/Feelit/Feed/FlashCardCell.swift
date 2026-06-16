import UIKit

// MARK: - FlashVoteView
/// Nút vote kiểu Locket: nền mờ + thanh fill theo % + nhãn + %.
final class FlashVoteView: UIView {
    private let fill = UIView()
    private let txtLabel = UILabel()
    private let pctLabel = UILabel()
    private var fillWidth: NSLayoutConstraint!
    private var percent = 0
    private(set) var isRevealed = false

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white.withAlphaComponent(0.14)
        layer.cornerRadius = 22
        clipsToBounds = true

        fill.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fill)

        txtLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        txtLabel.textColor = .white
        pctLabel.font = .systemFont(ofSize: 11, weight: .bold)
        pctLabel.textColor = UIColor.white.withAlphaComponent(0.75)

        let stack = UIStackView(arrangedSubviews: [txtLabel, pctLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        fillWidth = fill.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0)
        NSLayoutConstraint.activate([
            fill.leadingAnchor.constraint(equalTo: leadingAnchor),
            fill.topAnchor.constraint(equalTo: topAnchor),
            fill.bottomAnchor.constraint(equalTo: bottomAnchor),
            fillWidth,
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 58),
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Set nội dung gốc; mặc định CHƯA reveal (ẩn %, chưa có thanh fill).
    func configure(label: String, percent: Int, fillColor: UIColor) {
        txtLabel.text = label
        self.percent = percent
        fill.backgroundColor = fillColor
        setRevealed(false, selected: false, animated: false)
    }

    /// Hiện/ẩn kết quả. revealed=false → "chạm để chọn", fill 0.
    func setRevealed(_ revealed: Bool, selected: Bool, animated: Bool) {
        isRevealed = revealed
        pctLabel.text = revealed ? "\(percent)%" : "chạm để chọn"
        pctLabel.textColor = UIColor.white.withAlphaComponent(revealed ? 0.85 : 0.55)
        layer.borderWidth = (revealed && selected) ? 2 : 0
        layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor

        fillWidth.isActive = false
        let mult: CGFloat = revealed ? max(0.0001, CGFloat(percent) / 100) : 0.0001
        fillWidth = fill.widthAnchor.constraint(equalTo: widthAnchor, multiplier: mult)
        fillWidth.isActive = true

        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }

    @objc private func tapped() {
        guard !isRevealed else { return }   // chỉ vote 1 lần
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) { self.transform = .identity }
        })
        onTap?()
    }
}

// MARK: - FlashCardCell
/// Thẻ poll toàn màn hình kiểu Locket: nền gradient + overlay + nội dung.
final class FlashCardCell: UICollectionViewCell {
    static let reuseId = "FlashCardCell"

    private let card = UIView()
    private let gradientBG = GradientView(colors: [], start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1, y: 1))
    private let illustration = IllustrationView()
    private let overlay = GradientView(
        colors: [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.9).cgColor],
        start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 1))

    private let badge = ChipLabel(insets: .init(top: 5, left: 12, bottom: 5, right: 12))
    private let statValue = UILabel()
    private let statName = UILabel()
    private let statBox = UIView()

    private let avatarBox = UIView()
    private let avatarLetter = UILabel()
    private let authorLabel = UILabel()
    private let verified = UILabel()
    private let endsLabel = UILabel()
    private let contextLabel = UILabel()
    private let questionLabel = UILabel()
    private let yesVote = FlashVoteView()
    private let noVote = FlashVoteView()
    private let footerLabel = UILabel()

    private var hasVoted = false
    /// Báo VC lưu lựa chọn (true = vế YES/Tăng).
    var onVote: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        yesVote.onTap = { [weak self] in self?.vote(yes: true) }
        noVote.onTap = { [weak self] in self?.vote(yes: false) }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        card.layer.cornerRadius = 30
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        [gradientBG, illustration, overlay].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        // Top row
        statBox.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        statBox.layer.cornerRadius = 16
        statBox.translatesAutoresizingMaskIntoConstraints = false
        statValue.font = .systemFont(ofSize: 28, weight: .heavy)
        statValue.textColor = FeelitColors.bullish
        statName.font = .systemFont(ofSize: 8, weight: .heavy)
        statName.textColor = UIColor.white.withAlphaComponent(0.65)
        let statStack = UIStackView(arrangedSubviews: [statValue, statName])
        statStack.axis = .vertical
        statStack.alignment = .trailing
        statStack.translatesAutoresizingMaskIntoConstraints = false
        statBox.addSubview(statStack)

        let topRow = UIView()
        topRow.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(badge)
        topRow.addSubview(statBox)
        card.addSubview(topRow)

        // Author row
        avatarBox.backgroundColor = .white
        avatarBox.layer.cornerRadius = 8
        avatarBox.translatesAutoresizingMaskIntoConstraints = false
        avatarLetter.font = .systemFont(ofSize: 13, weight: .heavy)
        avatarLetter.textColor = .black
        avatarLetter.textAlignment = .center
        avatarLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarBox.addSubview(avatarLetter)

        authorLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        authorLabel.textColor = .white
        verified.text = "✓"
        verified.font = .systemFont(ofSize: 11, weight: .heavy)
        verified.textColor = FeelitColors.bullish
        endsLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        endsLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        let authorRow = UIStackView(arrangedSubviews: [avatarBox, authorLabel, verified, UIView(), endsLabel])
        authorRow.alignment = .center
        authorRow.spacing = 6

        contextLabel.font = .systemFont(ofSize: 12, weight: .medium)
        contextLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        contextLabel.numberOfLines = 1

        questionLabel.font = .systemFont(ofSize: 22, weight: .heavy)
        questionLabel.textColor = .white
        questionLabel.numberOfLines = 3

        let votes = UIStackView(arrangedSubviews: [yesVote, noVote])
        votes.distribution = .fillEqually
        votes.spacing = 10

        footerLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        footerLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        footerLabel.textAlignment = .center

        let bottom = UIStackView(arrangedSubviews: [authorRow, contextLabel, questionLabel, votes, footerLabel])
        bottom.axis = .vertical
        bottom.spacing = 10
        bottom.setCustomSpacing(6, after: authorRow)
        bottom.setCustomSpacing(14, after: questionLabel)
        bottom.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(bottom)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            gradientBG.topAnchor.constraint(equalTo: card.topAnchor),
            gradientBG.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            gradientBG.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            gradientBG.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            illustration.topAnchor.constraint(equalTo: card.topAnchor),
            illustration.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            illustration.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            illustration.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: card.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            topRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            topRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            topRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            badge.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            badge.topAnchor.constraint(equalTo: topRow.topAnchor),
            badge.bottomAnchor.constraint(lessThanOrEqualTo: topRow.bottomAnchor),
            statBox.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            statBox.topAnchor.constraint(equalTo: topRow.topAnchor),
            statBox.bottomAnchor.constraint(equalTo: topRow.bottomAnchor),
            statStack.topAnchor.constraint(equalTo: statBox.topAnchor, constant: 8),
            statStack.bottomAnchor.constraint(equalTo: statBox.bottomAnchor, constant: -8),
            statStack.leadingAnchor.constraint(equalTo: statBox.leadingAnchor, constant: 14),
            statStack.trailingAnchor.constraint(equalTo: statBox.trailingAnchor, constant: -14),

            bottom.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            bottom.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            bottom.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),

            avatarBox.widthAnchor.constraint(equalToConstant: 26),
            avatarBox.heightAnchor.constraint(equalToConstant: 26),
            avatarLetter.centerXAnchor.constraint(equalTo: avatarBox.centerXAnchor),
            avatarLetter.centerYAnchor.constraint(equalTo: avatarBox.centerYAnchor),
        ])
    }

    /// `voted` = nil nếu chưa vote; true/false nếu đã chọn YES/NO trước đó.
    func configure(with c: FlashCard, voted: Bool?) {
        gradientBG.setColors(c.gradientColors)
        illustration.kind = c.illustration
        badge.style(text: c.badge, textColor: .white, background: FeelitColors.bearish, corner: 12)
        statValue.text = "\(c.yesPercent)%"
        statName.text = c.statLabel
        avatarLetter.text = c.author.first.map { String($0).uppercased() } ?? "?"
        authorLabel.text = c.author
        endsLabel.text = c.endsIn
        contextLabel.text = c.context
        questionLabel.text = c.question
        yesVote.configure(label: c.yesLabel, percent: c.yesPercent, fillColor: FeelitColors.bullish.withAlphaComponent(0.4))
        noVote.configure(label: c.noLabel, percent: c.noPercent, fillColor: UIColor.white.withAlphaComponent(0.12))
        footerLabel.text = "+\(c.xp) XP nếu đúng · \(c.comments) bình luận"

        if let chose = voted {
            hasVoted = true
            reveal(selectedYes: chose, animated: false)
        } else {
            hasVoted = false
            statBox.isHidden = true   // ẩn % tổng cho tới khi vote
        }
    }

    // MARK: Vote
    private func vote(yes: Bool) {
        guard !hasVoted else { return }
        hasVoted = true
        reveal(selectedYes: yes, animated: true)
        onVote?(yes)
    }

    private func reveal(selectedYes: Bool, animated: Bool) {
        yesVote.setRevealed(true, selected: selectedYes, animated: animated)
        noVote.setRevealed(true, selected: !selectedYes, animated: animated)
        if animated {
            statBox.alpha = 0
            statBox.isHidden = false
            UIView.animate(withDuration: 0.4) { self.statBox.alpha = 1 }
        } else {
            statBox.alpha = 1
            statBox.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hasVoted = false
        statBox.isHidden = true
        statBox.alpha = 1
        yesVote.setRevealed(false, selected: false, animated: false)
        noVote.setRevealed(false, selected: false, animated: false)
    }
}
