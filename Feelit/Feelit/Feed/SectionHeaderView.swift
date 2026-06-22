import UIKit

// MARK: - SectionHeaderView
/// Header reusable cho các section: title bên trái + action button "Xem tất cả" bên phải.
final class SectionHeaderView: UICollectionReusableView {
    static let reuseId = "SectionHeaderView"

    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        titleLabel.font = FeelitFonts.heading
        titleLabel.textColor = FeelitColors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        actionButton.setTitle("Xem tất cả", for: .normal)
        actionButton.setTitleColor(FeelitColors.textSecondary, for: .normal)
        actionButton.titleLabel?.font = FeelitFonts.caption
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.lg),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.lg),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func actionTapped() { onAction?() }

    func configure(title: String, showAction: Bool) {
        titleLabel.text = title
        actionButton.isHidden = !showAction
        onAction = nil   // tránh closure cũ còn dính khi reuse
    }
}
