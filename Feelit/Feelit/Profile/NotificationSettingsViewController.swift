import UIKit

// MARK: - NotificationSettingsViewController
/// Trang cài đặt Thông báo (Figma 600-25953): mở khi bấm ô "Thông báo" trong Cài đặt.
/// Gồm công tắc tổng + các nhóm (Dự đoán / Cộng đồng / Thành tích / Hệ thống),
/// mỗi mục là một switch. Hỗ trợ cả light & dark mode qua bảng màu Theme.
final class NotificationSettingsViewController: UIViewController {

    private struct Item {
        let title: String
        let subtitle: String?
        let on: Bool
    }
    private struct Section {
        let title: String
        let caption: String
        let items: [Item]
    }

    private let sections: [Section] = [
        Section(title: "Dự đoán", caption: "Cập nhật về các poll bạn tham gia", items: [
            Item(title: "Kết quả poll", subtitle: "Khi poll bạn vote được giải quyết", on: true),
            Item(title: "Poll sắp kết thúc", subtitle: "Nhắc nhở 1 giờ trước khi đóng", on: true),
            Item(title: "Biến động thị trường", subtitle: "Khi tỷ lệ thay đổi mạnh (>10%)", on: false),
            Item(title: "Poll mới trong danh mục bạn theo", subtitle: "Crypto, thể thao và danh mục yêu thích", on: true),
        ]),
        Section(title: "Cộng đồng", caption: "Hoạt động liên quan đến bạn", items: [
            Item(title: "Người theo dõi mới", subtitle: nil, on: true),
            Item(title: "Nhắc đến bạn", subtitle: "Khi ai đó @mention trong bình luận", on: true),
            Item(title: "Bình luận", subtitle: "Bình luận trên dự đoán của bạn", on: true),
            Item(title: "Lượt thích", subtitle: "Khi dự đoán của bạn được thích", on: false),
            Item(title: "Trả lời bình luận", subtitle: "Khi ai đó trả lời comment của bạn", on: true),
        ]),
        Section(title: "Thành tích", caption: "Tiến trình và cột mốc", items: [
            Item(title: "Lên cấp độ", subtitle: "Khi bạn đạt đủ XP để lên level", on: true),
            Item(title: "Nhắc streak", subtitle: "Nhắc nhở hàng ngày để giữ streak", on: true),
            Item(title: "Vào top leaderboard", subtitle: "Khi bạn lọt vào top 100", on: true),
            Item(title: "Huy hiệu mới", subtitle: "Khi bạn nhận được thành tích mới", on: true),
        ]),
        Section(title: "Hệ thống", caption: "Thông báo về ứng dụng và tài khoản", items: [
            Item(title: "Cập nhật ứng dụng", subtitle: "Tính năng mới và cải tiến", on: false),
            Item(title: "Bản tin hàng tuần", subtitle: "Tóm tắt hoạt động & top dự đoán", on: false),
            Item(title: "Cảnh báo bảo mật", subtitle: "Đăng nhập từ thiết bị lạ", on: true),
        ]),
    ]

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var itemSwitches: [UISwitch] = []
    private let masterCaption = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupScroll()
        buildContent()
        updateMasterCaption()
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
        stack.addArrangedSubview(masterCard())
        for s in sections {
            stack.addArrangedSubview(sectionHeader(s.title, s.caption))
            var rows: [UIView] = []
            for (i, item) in s.items.enumerated() {
                rows.append(switchRow(title: item.title, subtitle: item.subtitle, on: item.on, isMaster: false))
                if i < s.items.count - 1 { rows.append(divider()) }
            }
            stack.addArrangedSubview(cardWrap(rows))
        }
    }

    // MARK: Master toggle
    private func masterCard() -> UIView {
        let title = label("Thông báo tổng", 14, .semibold, Theme.textPrimary)
        masterCaption.font = .systemFont(ofSize: 12, weight: .regular)
        masterCaption.textColor = Theme.textTertiary
        let textCol = UIStackView(arrangedSubviews: [title, masterCaption])
        textCol.axis = .vertical; textCol.spacing = 2

        let sw = makeSwitch(on: true)
        sw.addTarget(self, action: #selector(masterToggled(_:)), for: .valueChanged)

        let row = UIStackView(arrangedSubviews: [textCol, UIView(), sw])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 14, left: 16, bottom: 14, right: 16)
        return cardWrap([row])
    }

    @objc private func masterToggled(_ sw: UISwitch) {
        // Bật/tắt tổng → đồng bộ tất cả switch con.
        itemSwitches.forEach { $0.setOn(sw.isOn, animated: true) }
        updateMasterCaption()
    }

    private func updateMasterCaption() {
        let count = itemSwitches.filter { $0.isOn }.count
        masterCaption.text = "\(count) loại đang bật"
    }

    // MARK: Rows
    private func switchRow(title: String, subtitle: String?, on: Bool, isMaster: Bool) -> UIView {
        let titleLabel = label(title, 14, .medium, Theme.textPrimary)
        let textCol = UIStackView(arrangedSubviews: [titleLabel])
        textCol.axis = .vertical; textCol.spacing = 2
        if let s = subtitle { textCol.addArrangedSubview(label(s, 11, .regular, Theme.textTertiary)) }

        let sw = makeSwitch(on: on)
        sw.addTarget(self, action: #selector(itemToggled), for: .valueChanged)
        itemSwitches.append(sw)

        let row = UIStackView(arrangedSubviews: [textCol, UIView(), sw])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        return row
    }

    @objc private func itemToggled() { updateMasterCaption() }

    private func makeSwitch(on: Bool) -> UISwitch {
        let sw = UISwitch()
        sw.isOn = on
        sw.onTintColor = Theme.green
        sw.setContentHuggingPriority(.required, for: .horizontal)
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }

    // MARK: Building blocks
    private func sectionHeader(_ title: String, _ caption: String) -> UIView {
        let t = label(title.uppercased(), 11, .semibold, Theme.textSecondary)
        let c = label(caption, 11, .regular, Theme.textTertiary)
        let col = UIStackView(arrangedSubviews: [t, c])
        col.axis = .vertical; col.spacing = 3
        col.isLayoutMarginsRelativeArrangement = true
        col.layoutMargins = .init(top: 6, left: 4, bottom: 2, right: 4)
        return col
    }

    private func cardWrap(_ rows: [UIView]) -> UIView {
        let col = UIStackView(arrangedSubviews: rows)
        col.axis = .vertical; col.spacing = 0
        col.translatesAutoresizingMaskIntoConstraints = false
        let card = ThemeCardView()
        card.backgroundColor = Theme.card
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.borderUIColor = Theme.border
        card.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: card.topAnchor),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        return card
    }

    private func divider() -> UIView {
        let d = UIView()
        d.backgroundColor = Theme.border
        d.translatesAutoresizingMaskIntoConstraints = false
        d.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let inset = UIStackView(arrangedSubviews: [d])
        inset.isLayoutMarginsRelativeArrangement = true
        inset.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 0)
        return inset
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
