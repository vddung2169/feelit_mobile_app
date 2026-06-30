import UIKit

// MARK: - PrivacySettingsViewController
/// Trang Quyền riêng tư (Figma 600-25828 "Privacy Settings"): các công tắc + bộ chọn
/// đối tượng (Mọi người / Người theo dõi / Chỉ tôi) qua popup (Figma 600-25943).
/// Hỗ trợ light & dark qua bảng màu Theme.
final class PrivacySettingsViewController: UIViewController {

    private enum Row {
        case toggle(title: String, subtitle: String?, on: Bool)
        case picker(title: String, subtitle: String?, value: String)
    }
    private struct Section { let title: String, caption: String; let rows: [Row] }

    private let audienceOptions = ["Mọi người", "Người theo dõi", "Chỉ tôi"]

    private let sections: [Section] = [
        Section(title: "Hồ sơ", caption: "Kiểm soát ai có thể xem trang cá nhân của bạn.", rows: [
            .toggle(title: "Tài khoản riêng tư", subtitle: "Mọi người có thể xem hồ sơ của bạn", on: false),
            .toggle(title: "Hiển thị trạng thái hoạt động", subtitle: "Cho người khác biết khi bạn đang trực tuyến", on: true),
            .toggle(title: "Cho phép tìm kiếm qua email", subtitle: "Người dùng khác có thể tìm bạn bằng email", on: true),
        ]),
        Section(title: "Dự đoán & Số liệu", caption: "Quyết định ai thấy được thành tích của bạn.", rows: [
            .picker(title: "Lịch sử dự đoán", subtitle: "Ai có thể xem các dự đoán đã qua", value: "Mọi người"),
            .picker(title: "Độ chính xác & XP", subtitle: "Ai có thể thấy % chính xác và điểm XP", value: "Mọi người"),
        ]),
        Section(title: "Tương tác", caption: "Giới hạn ai có thể tương tác với bạn.", rows: [
            .picker(title: "Ai có thể nhắc đến bạn", subtitle: nil, value: "Mọi người"),
            .picker(title: "Ai có thể bình luận", subtitle: "Bình luận trên dự đoán của bạn", value: "Người theo dõi"),
            .toggle(title: "Cho phép nhắn tin trực tiếp", subtitle: "Nhận tin nhắn từ người không theo dõi", on: true),
        ]),
    ]

    private let scroll = UIScrollView()
    private let stack = UIStackView()

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
        for s in sections {
            stack.addArrangedSubview(sectionHeader(s.title, s.caption))
            var views: [UIView] = []
            for (i, r) in s.rows.enumerated() {
                views.append(rowView(r))
                if i < s.rows.count - 1 { views.append(divider()) }
            }
            stack.addArrangedSubview(cardWrap(views))
        }
        stack.addArrangedSubview(footer())
    }

    // MARK: Rows
    private func rowView(_ row: Row) -> UIView {
        switch row {
        case let .toggle(title, subtitle, on):
            let sw = UISwitch()
            sw.isOn = on
            sw.onTintColor = Theme.green
            sw.setContentHuggingPriority(.required, for: .horizontal)
            return baseRow(title: title, subtitle: subtitle, trailing: sw)
        case let .picker(title, subtitle, value):
            return baseRow(title: title, subtitle: subtitle, trailing: pickerChip(value: value))
        }
    }

    private func baseRow(title: String, subtitle: String?, trailing: UIView) -> UIView {
        let titleLabel = label(title, 14, .regular, Theme.textPrimary)
        let textCol = UIStackView(arrangedSubviews: [titleLabel])
        textCol.axis = .vertical; textCol.spacing = 2
        if let s = subtitle { textCol.addArrangedSubview(label(s, 12, .regular, Theme.textTertiary)) }

        let row = UIStackView(arrangedSubviews: [textCol, UIView(), trailing])
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = .init(top: 12, left: 16, bottom: 12, right: 16)
        return row
    }

    // MARK: Audience picker chip
    private func pickerChip(value: String) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.attributedTitle = AttributedString(value, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 11, weight: .light)]))
        c.image = UIImage(systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold))
        c.imagePlacement = .trailing
        c.imagePadding = 6
        c.baseForegroundColor = Theme.textPrimary
        c.background.backgroundColor = Theme.track
        c.background.cornerRadius = 8
        c.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 10)
        let b = UIButton(configuration: c)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.addAction(UIAction { [weak self, weak b] _ in
            guard let self, let b else { return }
            self.showAudiencePopup(from: b, current: b.configuration?.title ?? value)
        }, for: .touchUpInside)
        return b
    }

    private func showAudiencePopup(from chip: UIButton, current: String) {
        let popup = AudiencePopupView(options: audienceOptions, selected: current) { [weak chip] choice in
            guard let chip else { return }
            var cfg = chip.configuration
            cfg?.attributedTitle = AttributedString(choice, attributes:
                AttributeContainer([.font: UIFont.systemFont(ofSize: 11, weight: .light)]))
            chip.configuration = cfg
        }
        popup.present(over: view, anchoredTo: chip)
    }

    // MARK: Building blocks
    private func sectionHeader(_ title: String, _ caption: String) -> UIView {
        let t = label(title.uppercased(), 11, .semibold, Theme.textTertiary)
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

    private func footer() -> UIView {
        let l = label("Các thay đổi về quyền riêng tư sẽ được áp dụng ngay lập tức. Người dùng xem hồ sơ của bạn trước đó có thể vẫn thấy một số thông tin trong bộ nhớ cache.",
                      12, .regular, Theme.textTertiary)
        let wrap = UIStackView(arrangedSubviews: [l])
        wrap.isLayoutMarginsRelativeArrangement = true
        wrap.layoutMargins = .init(top: 8, left: 4, bottom: 0, right: 4)
        return wrap
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

// MARK: - AudiencePopupView
/// Popup chọn đối tượng (Figma 600-25943): thẻ nổi 3 lựa chọn, mục đang chọn tô xanh.
/// Bấm ra ngoài để đóng.
final class AudiencePopupView: UIView {

    private let options: [String]
    private let selected: String
    private let onSelect: (String) -> Void
    private let cardView = ThemeCardView()

    init(options: [String], selected: String, onSelect: @escaping (String) -> Void) {
        self.options = options
        self.selected = selected
        self.onSelect = onSelect
        super.init(frame: .zero)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        dismissTap.cancelsTouchesInView = false
        dismissTap.delegate = self
        addGestureRecognizer(dismissTap)
        buildCard()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildCard() {
        cardView.backgroundColor = Theme.surface
        cardView.layer.cornerRadius = 14
        cardView.layer.borderWidth = 1
        cardView.borderUIColor = Theme.border
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)

        let col = UIStackView()
        col.axis = .vertical; col.spacing = 0
        col.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: cardView.topAnchor),
            col.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])

        for (i, opt) in options.enumerated() {
            let isSel = opt == selected
            let l = UILabel()
            l.text = opt
            l.font = .systemFont(ofSize: 15, weight: isSel ? .semibold : .regular)
            l.textColor = isSel ? Theme.green : Theme.textPrimary
            l.translatesAutoresizingMaskIntoConstraints = false
            let rowBtn = UIControl()
            rowBtn.translatesAutoresizingMaskIntoConstraints = false
            rowBtn.addSubview(l)
            NSLayoutConstraint.activate([
                rowBtn.heightAnchor.constraint(equalToConstant: 52),
                rowBtn.widthAnchor.constraint(equalToConstant: 200),
                l.leadingAnchor.constraint(equalTo: rowBtn.leadingAnchor, constant: 20),
                l.centerYAnchor.constraint(equalTo: rowBtn.centerYAnchor),
            ])
            rowBtn.addAction(UIAction { [weak self] _ in
                self?.onSelect(opt)
                self?.dismiss()
            }, for: .touchUpInside)
            col.addArrangedSubview(rowBtn)
            if i < options.count - 1 {
                let d = UIView()
                d.backgroundColor = Theme.border
                d.translatesAutoresizingMaskIntoConstraints = false
                d.heightAnchor.constraint(equalToConstant: 1).isActive = true
                col.addArrangedSubview(d)
            }
        }
    }

    /// Hiển thị popup phủ toàn `host`, neo cạnh phải trên đỉnh `anchor`.
    func present(over host: UIView, anchoredTo anchor: UIView) {
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)

        let a = anchor.convert(anchor.bounds, to: self)
        // Mặc định đặt dưới chip, canh phải; nếu tràn đáy thì đặt trên.
        let belowTop = a.maxY + 6
        let willOverflow = belowTop + 158 > bounds.height - 20
        NSLayoutConstraint.activate([
            cardView.trailingAnchor.constraint(equalTo: leadingAnchor, constant: a.maxX),
        ])
        if willOverflow {
            cardView.bottomAnchor.constraint(equalTo: topAnchor, constant: a.minY - 6).isActive = true
        } else {
            cardView.topAnchor.constraint(equalTo: topAnchor, constant: belowTop).isActive = true
        }

        cardView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.16) {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
        }
    }

    @objc private func dismiss() {
        UIView.animate(withDuration: 0.14, animations: {
            self.cardView.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0
        }, completion: { _ in self.removeFromSuperview() })
    }

    // Chỉ nhận tap trên vùng phủ (để đóng); tap trên card xử lý riêng.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { true }
}

extension AudiencePopupView: UIGestureRecognizerDelegate {
    // Tap bên trong thẻ lựa chọn → để cho các nút xử lý, không đóng popup.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        !cardView.frame.contains(touch.location(in: self))
    }
}
