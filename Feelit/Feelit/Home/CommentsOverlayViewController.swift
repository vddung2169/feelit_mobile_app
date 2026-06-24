import UIKit

// MARK: - CommentsOverlayViewController
/// Overlay bình luận của một poll (Figma 454-12370). Hiện dạng bottom sheet tối,
/// gồm header "Trở lại" + chuông, danh sách bình luận, và ô nhập ở đáy.
final class CommentsOverlayViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private let item: PollCardItem
    init(item: PollCardItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // Mock data theo thiết kế.
    private struct OverlayComment {
        let username: String, text: String, vote: String, isUp: Bool, time: String
    }
    private let comments: [OverlayComment] = [
        .init(username: "fin.enjoyer", text: "Khả năng là sẽ tăng đấy các bảnh à",
              vote: "Tăng · 15% · 19 th 06", isUp: true, time: "3d"),
        .init(username: "Phantom", text: "Không giòn nha ae",
              vote: "Giảm · 5% · 19 th 06", isUp: false, time: "3d"),
        .init(username: "Tá Senu", text: "Chan đê",
              vote: "Tăng · 8% · 19 th 06", isUp: true, time: "3d"),
        .init(username: "Omaixai", text: "Tăng thì mai t phát khô gà cho",
              vote: "Tăng · 5% · 19 th 06", isUp: true, time: "3d"),
        .init(username: "mokejom.lord", text: "Không giòn nha ae",
              vote: "Giảm · 15% · 19 th 06", isUp: false, time: "3d"),
    ]

    private let scroll = UIScrollView()
    private let list = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = UIColor(hex: 0x181818)
        buildHeader()
        buildList()
        buildInputBar()
    }

    // MARK: Header
    private func buildHeader() {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "chevron.left",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        c.imagePadding = 4
        c.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 17, weight: .regular)]))
        c.baseForegroundColor = UIColor(hex: 0xEDEDED)
        c.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let back = UIButton(configuration: c)
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(close), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [back, UIView(), notifBell(), notifBell()])
        header.axis = .horizontal; header.spacing = 12; header.alignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        self.headerBottom = header.bottomAnchor
    }
    private var headerBottom: NSLayoutYAxisAnchor!

    // MARK: List
    private func buildList() {
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        list.axis = .vertical; list.spacing = 20
        list.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(list)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: headerBottom, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.topAnchor.constraint(equalTo: scroll.topAnchor),
            list.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            list.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            list.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            list.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32),
        ])
        comments.forEach { list.addArrangedSubview(commentRow($0)) }
    }

    private func commentRow(_ c: OverlayComment) -> UIView {
        let avatar = AvatarView(size: 40, fontSize: 16)
        avatar.configure(username: c.username)
        avatar.setContentHuggingPriority(.required, for: .horizontal)

        let name = label(c.username, 16, .medium, 0xEDEDED)
        let text = label(c.text, 14, .regular, 0xEDEDED); text.numberOfLines = 0

        let upColor: UInt32 = 0x4CAF50, downColor: UInt32 = 0xF44336
        let badge = PaddingLabel(insets: .init(top: 2, left: 8, bottom: 2, right: 8))
        badge.text = c.vote
        badge.font = .systemFont(ofSize: 11, weight: .medium)
        badge.textColor = UIColor(hex: c.isUp ? upColor : downColor)
        badge.backgroundColor = UIColor(hex: c.isUp ? 0x74FF7A : 0xEF5350, alpha: 0.15)
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        let badgeRow = UIStackView(arrangedSubviews: [badge, UIView()])
        badgeRow.axis = .horizontal

        let time = label(c.time, 12, .regular, 0x606060)
        let reply = label("Trả lời", 12, .regular, 0xB3B3B3)
        let footer = UIStackView(arrangedSubviews: [time, reply, UIView()])
        footer.axis = .horizontal; footer.spacing = 12

        let col = UIStackView(arrangedSubviews: [name, text, badgeRow, footer])
        col.axis = .vertical; col.spacing = 6
        col.setCustomSpacing(8, after: badgeRow)

        let row = UIStackView(arrangedSubviews: [avatar, col])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .top
        return row
    }

    // MARK: Input bar
    private func buildInputBar() {
        let box = UIView()
        box.backgroundColor = UIColor(hex: 0x292929)
        box.layer.cornerRadius = 16
        box.translatesAutoresizingMaskIntoConstraints = false

        let avatar = AvatarView(size: 24, fontSize: 11)
        avatar.configure(username: "you")
        let placeholder = label("Bạn đang nghĩ gì?", 13, .regular, 0x606060)

        var bc = UIButton.Configuration.filled()
        bc.baseBackgroundColor = UIColor(hex: 0x202020)
        bc.baseForegroundColor = UIColor(hex: 0xFBFBFB)
        bc.cornerStyle = .medium
        bc.image = UIImage(systemName: "arrow.up",
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        bc.imagePadding = 4
        bc.attributedTitle = AttributedString("Bình luận", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 11, weight: .medium)]))
        bc.contentInsets = .init(top: 6, leading: 10, bottom: 6, trailing: 10)
        let send = UIButton(configuration: bc)
        send.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [avatar, placeholder, UIView(), send])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)
        view.addSubview(box)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: box.topAnchor, constant: 8),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -8),
            row.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),

            box.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            box.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            box.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            scroll.bottomAnchor.constraint(equalTo: box.topAnchor, constant: -12),
        ])
    }

    // MARK: Helpers
    private func notifBell() -> UIView {
        let iv = UIImageView(image: UIImage(systemName: "bell",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)))
        iv.tintColor = UIColor(hex: 0x969696)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        let dot = UIView()
        dot.backgroundColor = UIColor(hex: 0xFE3333)
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(iv); wrap.addSubview(dot)
        NSLayoutConstraint.activate([
            wrap.widthAnchor.constraint(equalToConstant: 24),
            wrap.heightAnchor.constraint(equalToConstant: 24),
            iv.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
            dot.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 1),
            dot.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -1),
        ])
        return wrap
    }

    private func label(_ text: String, _ size: CGFloat, _ weight: UIFont.Weight, _ hex: UInt32) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = UIColor(hex: hex)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    @objc private func close() { dismiss(animated: true) }
}
