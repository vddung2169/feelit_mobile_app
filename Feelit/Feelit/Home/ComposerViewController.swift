import UIKit

// MARK: - ComposerViewController
/// Bottom sheet soạn bài đăng mới (Figma 481-24251 "Writing Pop-up"), kiểu Threads:
/// tiêu đề "Bài viết mới", avatar + tên + ô nhập "Bạn đang nghĩ gì?", thanh công cụ
/// (ảnh / GIF / poll / @) + nút Đăng.
final class ComposerViewController: UIViewController {

    private let username = "fin.enjoyer"
    private let textView = UITextView()
    private let placeholder = "Bạn đang nghĩ gì?"

    private lazy var postButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.baseBackgroundColor = Theme.track
        c.baseForegroundColor = Theme.textTertiary
        c.cornerStyle = .medium
        c.contentInsets = .init(top: 8, leading: 18, bottom: 8, trailing: 18)
        c.attributedTitle = AttributedString("Đăng", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 15, weight: .semibold)]))
        let b = UIButton(configuration: c)
        b.isEnabled = false
        b.addAction(UIAction { [weak self] _ in self?.post() }, for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.track

        let header = makeHeader()
        let body = makeBody()
        let toolbar = makeToolbar()
        [header, body, toolbar].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 48),

            body.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            body.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            body.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            body.bottomAnchor.constraint(lessThanOrEqualTo: toolbar.topAnchor, constant: -8),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 56),
            // Thanh công cụ luôn nằm trên bàn phím (và trên safe area khi chưa có bàn phím).
            toolbar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
    }

    // MARK: Header
    private func makeHeader() -> UIView {
        let title = IdeaUI.label("Bài viết mới", 15, .semibold, 0x202020)
        let hairline = UIView()
        hairline.backgroundColor = Theme.border
        hairline.translatesAutoresizingMaskIntoConstraints = false
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(title); wrap.addSubview(hairline)
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: wrap.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            hairline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),
        ])
        return wrap
    }

    // MARK: Body (avatar + username + text input)
    private func makeBody() -> UIView {
        let avatar = IdeaUI.avatar(username, size: 36, corner: 10, fontSize: 15)

        let name = IdeaUI.label(username, 14, .semibold, 0x202020)

        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15, weight: .regular)
        textView.textColor = Theme.textPrimary
        textView.text = placeholder
        textView.textColor = Theme.textTertiary
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [name, textView])
        col.axis = .vertical
        col.spacing = 4
        col.translatesAutoresizingMaskIntoConstraints = false

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(avatar); row.addSubview(col)
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: row.topAnchor),
            avatar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            col.topAnchor.constraint(equalTo: row.topAnchor),
            col.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            col.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    // MARK: Toolbar (attachments + Đăng)
    private func makeToolbar() -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false

        let hairline = UIView()
        hairline.backgroundColor = Theme.border
        hairline.translatesAutoresizingMaskIntoConstraints = false

        let attachments = UIStackView()
        attachments.axis = .horizontal
        attachments.spacing = 10
        attachments.alignment = .center
        attachments.translatesAutoresizingMaskIntoConstraints = false
        let icons = ["photo", "rectangle.stack", "chart.bar", "at"]
        for (i, name) in icons.enumerated() {
            attachments.addArrangedSubview(iconButton(name))
            if i < icons.count - 1 { attachments.addArrangedSubview(vDivider()) }
        }

        wrap.addSubview(hairline)
        wrap.addSubview(attachments)
        wrap.addSubview(postButton)
        postButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hairline.topAnchor.constraint(equalTo: wrap.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            attachments.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
            attachments.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),

            postButton.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
            postButton.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
        ])
        return wrap
    }

    private func iconButton(_ systemName: String) -> UIButton {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: systemName,
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
        c.baseForegroundColor = Theme.textTertiary
        c.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        return UIButton(configuration: c)
    }

    private func vDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = Theme.border
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 1).isActive = true
        v.heightAnchor.constraint(equalToConstant: 16).isActive = true
        return v
    }

    // MARK: Actions
    private func post() {
        // Mock: chỉ đóng sheet. Khi có BE sẽ gửi nội dung textView.text.
        view.endEditing(true)
        dismiss(animated: true)
    }

    private var hasText: Bool {
        !textView.text.isEmpty && textView.textColor != Theme.textTertiary
    }

    private func updatePostButton() {
        var c = postButton.configuration
        postButton.isEnabled = hasText
        c?.baseBackgroundColor = hasText ? Theme.textPrimary : Theme.track
        c?.baseForegroundColor = hasText ? Theme.page : Theme.textTertiary
        postButton.configuration = c
    }
}

// MARK: - UITextViewDelegate (placeholder + bật nút Đăng)
extension ComposerViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == Theme.textTertiary {
            textView.text = ""
            textView.textColor = Theme.textPrimary
        }
    }
    func textViewDidChange(_ textView: UITextView) { updatePostButton() }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeholder
            textView.textColor = Theme.textTertiary
        }
        updatePostButton()
    }
}
