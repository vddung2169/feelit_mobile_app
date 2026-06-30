import UIKit

// MARK: - SecuritySettingsViewController
/// Trang Bảo mật (Figma 600-26157): đổi mật khẩu, xác thực 2 bước (SMS / app),
/// danh sách phiên đăng nhập. Hỗ trợ light & dark qua bảng màu Theme.
final class SecuritySettingsViewController: UIViewController {

    private struct Device {
        let name: String, info: String
        let current: Bool
    }
    private let devices: [Device] = [
        .init(name: "iPhone 15 Pro", info: "Hà Nội, VN · Hiện tại", current: true),
        .init(name: "MacBook Pro", info: "Hà Nội, VN · 2 giờ trước", current: false),
        .init(name: "iPad Air", info: "TP. HCM, VN · 3 ngày trước", current: false),
    ]

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var methodIndex = 0   // 0 = SMS, 1 = app
    private var methodCards: [ThemeCardView] = []
    private var methodRadios: [UIImageView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupScroll()
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
        c.baseForegroundColor = Theme.textPrimary
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
        // MẬT KHẨU
        stack.addArrangedSubview(sectionHeader("Mật khẩu"))
        let pwRow = iconRow(icon: "key.fill", title: "Đổi mật khẩu", subtitle: nil,
                            trailing: chevron(), action: #selector(openChangePassword))
        stack.addArrangedSubview(cardWrap([pwRow]))

        // XÁC THỰC 2 BƯỚC
        stack.addArrangedSubview(sectionHeader("Xác thực 2 bước"))
        stack.addArrangedSubview(twoFactorCard())

        // PHIÊN ĐĂNG NHẬP
        stack.addArrangedSubview(sectionHeader("Phiên đăng nhập"))
        stack.addArrangedSubview(sessionsCard())
    }

    // MARK: 2FA
    private func twoFactorCard() -> UIView {
        let sw = UISwitch(); sw.isOn = true; sw.onTintColor = Theme.green
        sw.setContentHuggingPriority(.required, for: .horizontal)
        let toggleRow = iconRow(icon: "iphone", title: "Xác thực 2 bước", subtitle: "Đang bật", trailing: sw)

        let caption = label("Phương thức xác thực", 12, .regular, Theme.textTertiary)
        let capWrap = UIStackView(arrangedSubviews: [caption])
        capWrap.isLayoutMarginsRelativeArrangement = true
        capWrap.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)

        let sms = methodCard(index: 0, title: "Tin nhắn SMS", subtitle: "+84 *** *** 821")
        let app = methodCard(index: 1, title: "Ứng dụng xác thực", subtitle: "Google Authenticator, Authy...")
        let methods = UIStackView(arrangedSubviews: [sms, app])
        methods.axis = .vertical; methods.spacing = 10
        methods.isLayoutMarginsRelativeArrangement = true
        methods.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 12)

        let col = UIStackView(arrangedSubviews: [toggleRow, caption2Wrap(capWrap), methods])
        col.axis = .vertical; col.spacing = 12
        col.isLayoutMarginsRelativeArrangement = true
        col.layoutMargins = .init(top: 0, left: 0, bottom: 14, right: 0)
        updateMethodSelection()
        return cardWrapRaw(col)
    }

    private func caption2Wrap(_ v: UIView) -> UIView { v }

    private func methodCard(index: Int, title: String, subtitle: String) -> UIView {
        let radio = UIImageView()
        radio.contentMode = .scaleAspectFit
        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.widthAnchor.constraint(equalToConstant: 20).isActive = true
        radio.heightAnchor.constraint(equalToConstant: 20).isActive = true
        methodRadios.append(radio)

        let t = label(title, 14, .regular, Theme.textPrimary)
        let s = label(subtitle, 11, .regular, Theme.textTertiary)
        let textCol = UIStackView(arrangedSubviews: [t, s])
        textCol.axis = .vertical; textCol.spacing = 2

        let row = UIStackView(arrangedSubviews: [radio, textCol])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 14, bottom: 12, right: 14)

        let card = ThemeCardView()
        card.backgroundColor = Theme.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.borderUIColor = Theme.border
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        methodCards.append(card)
        let tap = MethodTapGesture(target: self, action: #selector(selectMethod(_:)))
        tap.index = index
        card.addGestureRecognizer(tap)
        return card
    }

    @objc private func selectMethod(_ g: MethodTapGesture) {
        methodIndex = g.index
        updateMethodSelection()
    }

    private func updateMethodSelection() {
        for (i, card) in methodCards.enumerated() {
            let sel = i == methodIndex
            card.borderUIColor = sel ? Theme.green : Theme.border
            let radio = methodRadios[i]
            radio.image = UIImage(systemName: sel ? "largecircle.fill.circle" : "circle",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
            radio.tintColor = sel ? Theme.green : Theme.textTertiary
        }
    }

    // MARK: Sessions
    private func sessionsCard() -> UIView {
        var rows: [UIView] = []
        for (i, d) in devices.enumerated() {
            rows.append(deviceRow(d))
            rows.append(thinDivider())
        }
        rows.append(signOutAllRow())
        return cardWrap(rows)
    }

    private func deviceRow(_ d: Device) -> UIView {
        let nameLabel = label(d.name, 14, .regular, Theme.textPrimary)
        let nameRow = UIStackView(arrangedSubviews: [nameLabel])
        nameRow.axis = .horizontal; nameRow.spacing = 8; nameRow.alignment = .center
        if d.current { nameRow.addArrangedSubview(badge("Hiện tại")) }
        nameRow.addArrangedSubview(UIView())

        let info = label(d.info, 11, .regular, Theme.textTertiary)
        let textCol = UIStackView(arrangedSubviews: [nameRow, info])
        textCol.axis = .vertical; textCol.spacing = 2

        let trailing: UIView = d.current ? UIView() : signOutPill()
        return iconRow(icon: "laptopcomputer", title: nil, subtitle: nil, customCenter: textCol, trailing: trailing)
    }

    private func signOutAllRow() -> UIView {
        let iconBg = UIView()
        iconBg.backgroundColor = Theme.red.withAlphaComponent(0.14)
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "rectangle.portrait.and.arrow.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)))
        icon.tintColor = Theme.red
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),
            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
        ])
        let t = label("Đăng xuất tất cả thiết bị", 14, .regular, Theme.red)
        let row = UIStackView(arrangedSubviews: [iconBg, t, UIView()])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 14, left: 16, bottom: 14, right: 16)
        return row
    }

    // MARK: Reusable
    private func iconRow(icon: String, title: String?, subtitle: String?,
                         customCenter: UIView? = nil, trailing: UIView,
                         action: Selector? = nil) -> UIView {
        let iconBg = UIView()
        iconBg.backgroundColor = Theme.border
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView(image: UIImage(systemName: icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)))
        iv.tintColor = Theme.textSecondary
        iv.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iv)
        NSLayoutConstraint.activate([
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),
            iv.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
        ])

        let center: UIView
        if let customCenter {
            center = customCenter
        } else {
            let t = label(title ?? "", 14, .medium, Theme.textPrimary)
            let col = UIStackView(arrangedSubviews: [t])
            col.axis = .vertical; col.spacing = 2
            if let s = subtitle { col.addArrangedSubview(label(s, 11, .regular, Theme.textTertiary)) }
            center = col
        }

        let row = UIStackView(arrangedSubviews: [iconBg, center, UIView(), trailing])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)

        if let action {
            let btn = UIButton(type: .system)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addTarget(self, action: action, for: .touchUpInside)
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

    @objc private func openChangePassword() {
        navigationController?.pushViewController(ChangePasswordViewController(), animated: true)
    }

    private func badge(_ text: String) -> UIView {
        let l = label(text, 10, .medium, Theme.green)
        l.translatesAutoresizingMaskIntoConstraints = false
        let wrap = UIView()
        wrap.backgroundColor = Theme.green.withAlphaComponent(0.15)
        wrap.layer.cornerRadius = 6
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(l)
        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 2),
            l.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -2),
            l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 7),
            l.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -7),
        ])
        wrap.setContentHuggingPriority(.required, for: .horizontal)
        return wrap
    }

    private func signOutPill() -> UIView {
        let l = label("Đăng xuất", 11, .light, Theme.red)
        l.translatesAutoresizingMaskIntoConstraints = false
        let wrap = UIView()
        wrap.backgroundColor = Theme.red.withAlphaComponent(0.12)
        wrap.layer.cornerRadius = 8
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(l)
        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 6),
            l.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -6),
            l.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            l.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
        ])
        wrap.setContentHuggingPriority(.required, for: .horizontal)
        return wrap
    }

    private func sectionHeader(_ title: String) -> UIView {
        let l = label(title.uppercased(), 11, .semibold, Theme.textSecondary)
        let wrap = UIStackView(arrangedSubviews: [l])
        wrap.isLayoutMarginsRelativeArrangement = true
        wrap.layoutMargins = .init(top: 6, left: 4, bottom: 0, right: 4)
        return wrap
    }

    private func cardWrap(_ rows: [UIView]) -> UIView {
        let col = UIStackView(arrangedSubviews: rows)
        col.axis = .vertical; col.spacing = 0
        return cardWrapRaw(col)
    }

    private func cardWrapRaw(_ content: UIView) -> UIView {
        content.translatesAutoresizingMaskIntoConstraints = false
        let card = ThemeCardView()
        card.backgroundColor = Theme.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.borderUIColor = Theme.border
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        return card
    }

    private func thinDivider() -> UIView {
        let d = UIView()
        d.backgroundColor = Theme.border
        d.translatesAutoresizingMaskIntoConstraints = false
        d.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let inset = UIStackView(arrangedSubviews: [d])
        inset.isLayoutMarginsRelativeArrangement = true
        inset.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 0)
        return inset
    }

    private func chevron() -> UIImageView {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)))
        iv.tintColor = Theme.textTertiary
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
}

// MARK: - MethodTapGesture
private final class MethodTapGesture: UITapGestureRecognizer { var index = 0 }
