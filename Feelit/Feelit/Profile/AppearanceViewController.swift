import UIKit

// MARK: - AppearanceViewController
/// Màn chọn giao diện (mở từ ô "Giao diện" trong Cài đặt): Sáng / Tối / Tự động.
/// Lựa chọn được lưu lại và áp dụng cho toàn app ngay lập tức.
final class AppearanceViewController: UIViewController {

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var rows: [AppTheme: UIView] = [:]
    private var checks: [AppTheme: UIImageView] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupScroll()
        buildContent()
    }

    private func setupHeader() {
        let back = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        c.imagePadding = 4
        c.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        c.baseForegroundColor = Theme.textPrimary
        c.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        back.configuration = c
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        let title = UILabel()
        title.text = "Giao diện"
        title.font = .systemFont(ofSize: 22, weight: .medium)
        title.textColor = Theme.textPrimary
        title.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(back); view.addSubview(title)
        NSLayoutConstraint.activate([
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            title.topAnchor.constraint(equalTo: back.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInset.bottom = 40
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 92),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        let header = UILabel()
        header.text = "CHỦ ĐỀ"
        header.font = .systemFont(ofSize: 11, weight: .semibold)
        header.textColor = Theme.textTertiary
        let headerWrap = UIStackView(arrangedSubviews: [header])
        headerWrap.isLayoutMarginsRelativeArrangement = true
        headerWrap.layoutMargins = .init(top: 0, left: 4, bottom: 0, right: 0)
        stack.addArrangedSubview(headerWrap)

        let card = ThemeCardView()
        card.backgroundColor = Theme.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.borderUIColor = Theme.border
        let col = UIStackView()
        col.axis = .vertical
        col.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: card.topAnchor),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        let themes = AppTheme.allCases
        for (i, t) in themes.enumerated() {
            col.addArrangedSubview(themeRow(t))
            if i < themes.count - 1 {
                let d = UIView()
                d.backgroundColor = Theme.border
                d.translatesAutoresizingMaskIntoConstraints = false
                d.heightAnchor.constraint(equalToConstant: 1).isActive = true
                let inset = UIStackView(arrangedSubviews: [d])
                inset.isLayoutMarginsRelativeArrangement = true
                inset.layoutMargins = .init(top: 0, left: 52, bottom: 0, right: 0)
                col.addArrangedSubview(inset)
            }
        }
        stack.addArrangedSubview(card)
        updateChecks()
    }

    private func themeRow(_ t: AppTheme) -> UIView {
        let iconBg = UIView()
        iconBg.backgroundColor = Theme.border
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: t.icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)))
        icon.tintColor = Theme.textSecondary
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
        ])

        let title = UILabel()
        title.text = t.title
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textColor = Theme.textPrimary
        let sub = UILabel()
        sub.text = t.subtitle
        sub.font = .systemFont(ofSize: 12, weight: .regular)
        sub.textColor = Theme.textTertiary
        let textCol = UIStackView(arrangedSubviews: [title, sub])
        textCol.axis = .vertical; textCol.spacing = 2

        let check = UIImageView(image: UIImage(systemName: "checkmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)))
        check.tintColor = Theme.green
        check.setContentHuggingPriority(.required, for: .horizontal)
        checks[t] = check

        let row = UIStackView(arrangedSubviews: [iconBg, textCol, UIView(), check])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 14, left: 16, bottom: 14, right: 16)
        row.isUserInteractionEnabled = true
        let tap = ThemeTapGesture(target: self, action: #selector(selectTheme(_:)))
        tap.theme = t
        row.addGestureRecognizer(tap)
        rows[t] = row
        return row
    }

    @objc private func selectTheme(_ g: ThemeTapGesture) {
        ThemeManager.shared.current = g.theme
        updateChecks()
    }

    private func updateChecks() {
        let cur = ThemeManager.shared.current
        for (t, check) in checks { check.isHidden = (t != cur) }
    }
}

// MARK: - ThemeTapGesture
/// Tap gesture mang theo lựa chọn theme tương ứng.
private final class ThemeTapGesture: UITapGestureRecognizer {
    var theme: AppTheme = .system
}
