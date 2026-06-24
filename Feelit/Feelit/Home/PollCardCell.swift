import UIKit

protocol PollCardCellDelegate: AnyObject {
    func pollCardDidSelect(_ item: PollCardItem)
    func pollCardDidTapComment(_ item: PollCardItem)
    func pollCardDidTapShare(_ item: PollCardItem, from cell: PollCardCell)
    func pollCardDidToggleSave(_ item: PollCardItem, saved: Bool)
}

// MARK: - PollCardCell
/// Thẻ poll full-screen (Figma 219-5411): nền gradient + scrim, badge thịnh hành,
/// rail hành động bên phải, nội dung + nút Tăng/Giảm ở đáy.
final class PollCardCell: UICollectionViewCell {

    static let reuseId = "PollCardCell"
    weak var delegate: PollCardCellDelegate?
    private var item: PollCardItem?
    private var isSaved = false

    private let card = GradientView(colors: [])
    private let scrim = GradientView(
        colors: [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.78).cgColor],
        start: CGPoint(x: 0.5, y: 0.3), end: CGPoint(x: 0.5, y: 1))

    // Badge thịnh hành
    private let badge: UILabel = {
        let l = PaddingLabel(insets: .init(top: 4, left: 10, bottom: 4, right: 10))
        l.text = "🔥 Đang thịnh hành"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor(hex: 0xE6E6E6)
        l.backgroundColor = AuthTheme.bad
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Asset + title
    private let assetBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let assetLabel = PollCardCell.makeLabel(16, .regular, 0xEDEDED)
    private let titleLabel: UILabel = {
        let l = makeLabel(20, .medium, 0xEDEDED)
        l.numberOfLines = 0
        return l
    }()
    private let votersLabel = PollCardCell.makeLabel(12, .regular, 0xB3B3B3)

    private lazy var upButton = makeVoteButton("Tăng", color: 0x4CAF50)
    private lazy var downButton = makeVoteButton("Giảm", color: 0xF44336)

    // Rail hành động
    private let commentItem = ActionRailItem(icon: "bubble.right.fill")
    private let saveItem = ActionRailItem(icon: "bookmark.fill")
    private let shareItem = ActionRailItem(icon: "arrowshape.turn.up.right.fill", caption: "Share")
    private let rail = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        scrim.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(scrim)

        let assetRow = UIStackView(arrangedSubviews: [assetBadge, assetLabel])
        assetRow.axis = .horizontal; assetRow.spacing = 8; assetRow.alignment = .center

        let buttons = UIStackView(arrangedSubviews: [upButton, downButton])
        buttons.axis = .horizontal; buttons.spacing = 12; buttons.distribution = .fillEqually

        let bottom = UIStackView(arrangedSubviews: [assetRow, titleLabel, buttons, votersLabel])
        bottom.axis = .vertical; bottom.spacing = 12; bottom.alignment = .fill
        bottom.setCustomSpacing(14, after: titleLabel)
        bottom.setCustomSpacing(8, after: buttons)
        bottom.translatesAutoresizingMaskIntoConstraints = false

        [commentItem, saveItem, shareItem].forEach { rail.addArrangedSubview($0) }
        rail.axis = .vertical; rail.spacing = 18; rail.alignment = .center
        rail.translatesAutoresizingMaskIntoConstraints = false
        commentItem.onTap = { [weak self] in self?.commentTapped() }
        saveItem.onTap = { [weak self] in self?.saveTapped() }
        shareItem.onTap = { [weak self] in self?.shareTapped() }

        card.addSubview(badge)
        card.addSubview(rail)
        card.addSubview(bottom)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -90),

            scrim.topAnchor.constraint(equalTo: card.topAnchor),
            scrim.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            scrim.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            scrim.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            rail.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rail.bottomAnchor.constraint(equalTo: bottom.topAnchor, constant: -16),

            bottom.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            bottom.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            bottom.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),

            assetBadge.widthAnchor.constraint(equalToConstant: 28),
            assetBadge.heightAnchor.constraint(equalToConstant: 28),
            upButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.delegate = self
        card.addGestureRecognizer(tap)
        upButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        downButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    func configure(with item: PollCardItem, isSaved: Bool) {
        self.item = item
        self.isSaved = isSaved
        card.setColors(item.gradientColors)
        badge.isHidden = !item.trending
        assetBadge.text = item.assetEmoji
        assetBadge.backgroundColor = UIColor(hex: item.assetColor)
        assetLabel.text = item.assetSymbol
        titleLabel.text = item.title
        votersLabel.text = item.votersText
        commentItem.setCount(item.commentCount)
        saveItem.setCount(item.saveCount)
        applySaveStyle()
    }

    private func applySaveStyle() {
        saveItem.setIconColor(isSaved ? UIColor(hex: 0xFFC107) : .white)
    }

    @objc private func tapped() {
        guard let item = item else { return }
        delegate?.pollCardDidSelect(item)
    }

    private func commentTapped() {
        guard let item = item else { return }
        delegate?.pollCardDidTapComment(item)
    }

    private func saveTapped() {
        guard let item = item else { return }
        isSaved.toggle()
        applySaveStyle()
        delegate?.pollCardDidToggleSave(item, saved: isSaved)
    }

    private func shareTapped() {
        guard let item = item else { return }
        delegate?.pollCardDidTapShare(item, from: self)
    }

    // MARK: Factories
    private static func makeLabel(_ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = UIColor(hex: hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func makeVoteButton(_ title: String, color: UInt32) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(hex: color)
        config.baseForegroundColor = UIColor(hex: 0xEDEDED)
        config.cornerStyle = .large
        config.attributedTitle = AttributedString(title, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        return b
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PollCardCell: UIGestureRecognizerDelegate {
    /// Bỏ qua chạm rơi vào rail hành động — để các nút rail tự xử lý, không mở chi tiết.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        if let v = touch.view, v.isDescendant(of: rail) { return false }
        return true
    }
}

// MARK: - ActionRailItem
final class ActionRailItem: UIView {
    private let iconView = UIImageView()
    private let label = UILabel()

    /// Gọi khi người dùng chạm vào mục này.
    var onTap: (() -> Void)?

    init(icon: String, caption: String? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon,
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        label.text = caption ?? ""
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView); addSubview(label)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 26),
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func handleTap() {
        onTap?()
        // Phản hồi chạm nhẹ.
        alpha = 0.5
        UIView.animate(withDuration: 0.2) { self.alpha = 1 }
    }

    func setCount(_ count: Int) { label.text = "\(count)" }
    func setIconColor(_ color: UIColor) { iconView.tintColor = color }
}

// MARK: - PaddingLabel
final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) { self.insets = insets; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}
