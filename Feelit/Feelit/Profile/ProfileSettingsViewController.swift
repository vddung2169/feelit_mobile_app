import UIKit

// MARK: - ProfileSettingsViewController
/// Trang Cài đặt (Figma 600-25553 "Profile | Settings", light mode): mở khi bấm icon
/// gearshape ở trang Profile. Gồm nút quay lại, ô hồ sơ, các nhóm cài đặt
/// (Quyền riêng tư / Thông báo / Giao diện / Hỗ trợ / Tài khoản) và footer phiên bản.
final class ProfileSettingsViewController: UIViewController {

    private enum P {
        static let page   = Theme.page
        static let card   = Theme.card
        static let border = Theme.border
        static let text   = Theme.textPrimary
        static let sub    = Theme.textSecondary
        static let muted  = Theme.textTertiary
        static let red    = Theme.red
    }

    private struct Row {
        let icon: String, title: String, subtitle: String?
        var value: String? = nil
        var destructive: Bool = false
        var action: (() -> Void)? = nil
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = P.page
        setupHeader()
        setupScroll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dựng lại để giá trị "Giao diện" luôn khớp theme hiện tại.
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildContent()
    }

    // MARK: Header
    private func setupHeader() {
        let back = UIButton(type: .system)
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        c.imagePadding = 4
        c.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        c.baseForegroundColor = P.text
        c.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        back.configuration = c
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        view.addSubview(back)
        NSLayoutConstraint.activate([
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
        ])
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInset.bottom = 110
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(profileButton())

        stack.addArrangedSubview(sectionLabel("QUYỀN RIÊNG TƯ"))
        stack.addArrangedSubview(card([
            Row(icon: "lock.fill", title: "Quyền riêng tư", subtitle: "Hồ sơ, lịch sử dự đoán, số liệu"),
            Row(icon: "shield.fill", title: "Bảo mật", subtitle: "Mật khẩu, xác thực 2 bước"),
        ]))

        stack.addArrangedSubview(sectionLabel("THÔNG BÁO"))
        stack.addArrangedSubview(card([
            Row(icon: "bell.fill", title: "Thông báo", subtitle: "Kết quả poll, nhắc đến, người theo dõi",
                action: { [weak self] in self?.openNotifications() }),
        ]))

        stack.addArrangedSubview(sectionLabel("GIAO DIỆN"))
        stack.addArrangedSubview(card([
            Row(icon: ThemeManager.shared.current.icon, title: "Giao diện", subtitle: "Chủ đề, ngôn ngữ",
                value: ThemeManager.shared.current.title,
                action: { [weak self] in self?.openAppearance() }),
        ]))

        stack.addArrangedSubview(sectionLabel("HỖ TRỢ"))
        stack.addArrangedSubview(card([
            Row(icon: "questionmark.circle.fill", title: "Trợ giúp & phản hồi", subtitle: nil),
            Row(icon: "doc.text.fill", title: "Điều khoản sử dụng", subtitle: nil),
            Row(icon: "hand.raised.fill", title: "Chính sách quyền riêng tư", subtitle: nil),
        ]))

        stack.addArrangedSubview(sectionLabel("TÀI KHOẢN"))
        stack.addArrangedSubview(card([
            Row(icon: "rectangle.portrait.and.arrow.right", title: "Đăng xuất", subtitle: nil,
                destructive: true, action: { [weak self] in self?.logout() }),
            Row(icon: "trash.fill", title: "Xóa tài khoản", subtitle: "Không thể khôi phục", destructive: true),
        ]))

        stack.addArrangedSubview(footer())
    }

    // MARK: Profile button
    private func profileButton() -> UIView {
        let avatar = IdeaUI.avatar("fin.enjoyer", size: 52, corner: 12, fontSize: 20)
        let name = label("fin.enjoyer", 15, .semibold, P.text)
        let sub = label("@ilovefinance · Chỉnh sửa hồ sơ", 12, .regular, P.sub)
        let col = UIStackView(arrangedSubviews: [name, sub])
        col.axis = .vertical; col.spacing = 3
        let row = UIStackView(arrangedSubviews: [avatar, col, UIView(), chevron()])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        let cardView = card(content: row, radius: 12)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openEditProfile))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
        return cardView
    }

    @objc private func openEditProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }

    private func openAppearance() {
        navigationController?.pushViewController(AppearanceViewController(), animated: true)
    }

    private func openNotifications() {
        navigationController?.pushViewController(NotificationSettingsViewController(), animated: true)
    }

    // MARK: Section card (rows + dividers)
    private func card(_ rows: [Row]) -> UIView {
        var children: [UIView] = []
        for (i, r) in rows.enumerated() {
            children.append(rowView(r))
            if i < rows.count - 1 {
                let d = UIView()
                d.backgroundColor = P.border
                d.translatesAutoresizingMaskIntoConstraints = false
                d.heightAnchor.constraint(equalToConstant: 1).isActive = true
                let inset = UIStackView(arrangedSubviews: [d])
                inset.isLayoutMarginsRelativeArrangement = true
                inset.layoutMargins = .init(top: 0, left: 52, bottom: 0, right: 0)
                children.append(inset)
            }
        }
        let col = UIStackView(arrangedSubviews: children)
        col.axis = .vertical; col.spacing = 0
        let c = ThemeCardView()
        c.backgroundColor = P.card
        c.layer.cornerRadius = 12
        c.layer.borderWidth = 1
        c.borderUIColor = P.border
        col.translatesAutoresizingMaskIntoConstraints = false
        c.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: c.topAnchor),
            col.leadingAnchor.constraint(equalTo: c.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: c.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: c.bottomAnchor),
        ])
        return c
    }

    private func rowView(_ r: Row) -> UIView {
        let iconBg = UIView()
        iconBg.backgroundColor = r.destructive ? P.red : P.border
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: r.icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)))
        icon.tintColor = r.destructive ? .white : P.sub
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
        ])

        let title = label(r.title, 14, .medium, r.destructive ? P.red : P.text)
        let textCol = UIStackView(arrangedSubviews: [title])
        textCol.axis = .vertical; textCol.spacing = 2
        if let s = r.subtitle { textCol.addArrangedSubview(label(s, 12, .regular, P.muted)) }

        let rightStack = UIStackView()
        rightStack.axis = .horizontal; rightStack.spacing = 8; rightStack.alignment = .center
        if let v = r.value { rightStack.addArrangedSubview(label(v, 12, .regular, P.muted)) }
        rightStack.addArrangedSubview(chevron())
        rightStack.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconBg, textCol, UIView(), rightStack])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 14, left: 16, bottom: 14, right: 16)
        row.isUserInteractionEnabled = true

        if let action = r.action {
            let btn = UIButton(type: .system)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
            row.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: row.topAnchor),
                btn.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                btn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                btn.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            ])
        }
        return row
    }

    // MARK: Bits
    private func sectionLabel(_ text: String) -> UIView {
        let l = label(text, 11, .semibold, P.muted)
        let wrap = UIStackView(arrangedSubviews: [l])
        wrap.isLayoutMarginsRelativeArrangement = true
        wrap.layoutMargins = .init(top: 6, left: 4, bottom: 0, right: 0)
        return wrap
    }

    private func footer() -> UIView {
        let l = label("Feelit v1.0.0", 11, .regular, P.muted)
        l.textAlignment = .center
        let wrap = UIStackView(arrangedSubviews: [l])
        wrap.isLayoutMarginsRelativeArrangement = true
        wrap.layoutMargins = .init(top: 12, left: 0, bottom: 0, right: 0)
        return wrap
    }

    private func card(content: UIView, radius: CGFloat) -> UIView {
        let c = ThemeCardView()
        c.backgroundColor = P.card
        c.layer.cornerRadius = radius
        c.layer.borderWidth = 1
        c.borderUIColor = P.border
        content.translatesAutoresizingMaskIntoConstraints = false
        c.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: c.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -14),
        ])
        return c
    }

    private func chevron() -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)))
        iv.tintColor = P.muted
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }

    private func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    // MARK: Actions
    private func logout() {
        let alert = UIAlertController(title: "Đăng xuất",
            message: "Bạn có chắc muốn đăng xuất khỏi tài khoản này?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    private func performLogout() {
        guard let window = view.window else { return }
        let welcome = WelcomeViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = welcome
        }
    }
}
