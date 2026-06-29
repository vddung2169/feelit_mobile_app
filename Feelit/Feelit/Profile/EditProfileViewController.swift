import UIKit

// MARK: - EditProfileViewController
/// Màn "Chỉnh sửa hồ sơ" (Figma 600-25766 default / 600-25707 trạng thái lỗi, light mode):
/// mở khi bấm ô hồ sơ ở trang Cài đặt. Gồm avatar + nút đổi ảnh, các ô nhập
/// (Tên hiển thị / Tên người dùng / Giới thiệu / Email) có đếm ký tự + xác thực,
/// nút "Lưu" chỉ bật khi mọi trường hợp lệ.
final class EditProfileViewController: UIViewController {

    enum P {
        static let page   = Theme.surface
        static let card   = Theme.card
        static let border = Theme.border
        static let text   = Theme.textPrimary
        static let sub    = Theme.textSecondary
        static let muted  = Theme.textTertiary
        static let green  = Theme.green
        static let red    = Theme.red
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var saveButton: UIButton!
    private var fields: [EditField] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = P.page
        setupHeader()
        setupScroll()
        buildContent()
        revalidate()
    }

    // MARK: Header (Trở lại + Lưu)
    private func setupHeader() {
        let back = UIButton(type: .system)
        var bc = UIButton.Configuration.plain()
        bc.image = UIImage(systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        bc.imagePadding = 4
        bc.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .regular)]))
        bc.baseForegroundColor = P.text
        bc.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        back.configuration = bc
        back.translatesAutoresizingMaskIntoConstraints = false
        back.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        var sc = UIButton.Configuration.filled()
        sc.baseBackgroundColor = P.green
        sc.cornerStyle = .medium
        sc.contentInsets = .init(top: 7, leading: 16, bottom: 7, trailing: 16)
        sc.attributedTitle = AttributedString("Lưu", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]))
        saveButton = UIButton(configuration: sc)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        view.addSubview(back); view.addSubview(saveButton)
        NSLayoutConstraint.activate([
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            saveButton.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    @objc private func save() {
        guard saveButton.isEnabled else { return }
        // Mock: chỉ quay lại. Khi có BE sẽ gửi dữ liệu các trường.
        navigationController?.popViewController(animated: true)
    }

    private func setupScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInset.bottom = 120
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(avatarBlock())

        let displayName = EditField(title: "Tên hiển thị", value: "fin.enjoyer", maxLen: 50,
            helper: "Tên sẽ hiển thị trên hồ sơ và trong các bình luận.") { t in
            let n = t.trimmingCharacters(in: .whitespaces)
            if n.count < 3 || n.count > 50 { return "Tên hiển thị phải từ 3 đến 50 ký tự." }
            return nil
        }

        let username = EditField(title: "Tên người dùng", value: "ilovefinance", maxLen: 30,
            helper: "Chỉ dùng chữ cái, số, dấu chấm và dấu gạch dưới.", prefix: "@") { t in
            if t.count < 3 || t.count > 30 { return "Tên người dùng phải từ 3 đến 30 ký tự." }
            if t.range(of: "^[A-Za-z0-9._]+$", options: .regularExpression) == nil {
                return "Chỉ gồm chữ cái, số, dấu chấm (.) hoặc dấu gạch dưới (_)."
            }
            return nil
        }

        let bio = EditField(title: "Giới thiệu", value: "", maxLen: 160,
            helper: nil, placeholder: "Viết vài dòng về bạn...", multiline: true) { _ in nil }

        let email = EditField(title: "Email", value: "", maxLen: 254,
            helper: "Email không hiển thị công khai.", placeholder: "your@email.com") { t in
            if t.isEmpty { return nil }
            if t.range(of: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", options: .regularExpression) == nil {
                return "Email không hợp lệ"
            }
            return nil
        }

        fields = [displayName, username, bio, email]
        fields.forEach { f in
            f.onChange = { [weak self] in self?.revalidate() }
            stack.addArrangedSubview(f)
        }
    }

    private func revalidate() {
        let allValid = fields.allSatisfy { $0.validate() }
        saveButton.isEnabled = allValid
        var c = saveButton.configuration
        c?.baseBackgroundColor = allValid ? P.green : P.border
        c?.attributedTitle = AttributedString("Lưu", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                                 .foregroundColor: allValid ? Theme.onAccent : P.muted]))
        saveButton.configuration = c
    }

    // MARK: Avatar block
    private func avatarBlock() -> UIView {
        let avatar = IdeaUI.avatar("fin.enjoyer", size: 96, corner: 8, fontSize: 38)

        let cam = ThemeCardView()
        cam.backgroundColor = Theme.track
        cam.layer.cornerRadius = 14
        cam.layer.borderWidth = 1
        cam.borderUIColor = Theme.borderStrong
        cam.translatesAutoresizingMaskIntoConstraints = false
        let camIcon = UIImageView(image: UIImage(systemName: "camera.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)))
        camIcon.tintColor = P.sub
        camIcon.translatesAutoresizingMaskIntoConstraints = false
        cam.addSubview(camIcon)

        let avatarWrap = UIView()
        avatarWrap.translatesAutoresizingMaskIntoConstraints = false
        avatarWrap.addSubview(avatar)
        avatarWrap.addSubview(cam)
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: avatarWrap.topAnchor),
            avatar.bottomAnchor.constraint(equalTo: avatarWrap.bottomAnchor),
            avatar.centerXAnchor.constraint(equalTo: avatarWrap.centerXAnchor),
            cam.widthAnchor.constraint(equalToConstant: 28),
            cam.heightAnchor.constraint(equalToConstant: 28),
            cam.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 4),
            cam.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 4),
            camIcon.centerXAnchor.constraint(equalTo: cam.centerXAnchor),
            camIcon.centerYAnchor.constraint(equalTo: cam.centerYAnchor),
        ])

        let caption = UILabel()
        caption.text = "Thay đổi ảnh đại diện"
        caption.font = .systemFont(ofSize: 12, weight: .regular)
        caption.textColor = P.text

        let col = UIStackView(arrangedSubviews: [avatarWrap, caption])
        col.axis = .vertical; col.spacing = 12; col.alignment = .center

        let tap = UITapGestureRecognizer(target: self, action: #selector(changeAvatar))
        col.isUserInteractionEnabled = true
        col.addGestureRecognizer(tap)
        return col
    }

    @objc private func changeAvatar() {
        // Mock: chưa có picker ảnh. Khi tích hợp sẽ mở PHPicker.
    }
}

// MARK: - EditField
/// Một ô nhập trong form chỉnh sửa hồ sơ: nhãn, ô nhập (1 dòng hoặc nhiều dòng),
/// bộ đếm ký tự, dòng trợ giúp (đổi sang đỏ khi lỗi).
final class EditField: UIView {

    private typealias P = EditProfileViewController.P
    var onChange: (() -> Void)?

    private let maxLen: Int
    private let helperText: String?
    private let validator: (String) -> String?

    private let counter = UILabel()
    private let helperLabel = UILabel()
    private let container = ThemeCardView()
    private let multiline: Bool
    private var textField: UITextField?
    private var textView: UITextView?
    private let placeholderText: String?

    var text: String {
        if let tf = textField { return tf.text ?? "" }
        let t = textView?.text ?? ""
        return t == placeholderText ? "" : t
    }

    init(title: String, value: String, maxLen: Int, helper: String?,
         prefix: String? = nil, placeholder: String? = nil, multiline: Bool = false,
         validator: @escaping (String) -> String?) {
        self.maxLen = maxLen
        self.helperText = helper
        self.validator = validator
        self.multiline = multiline
        self.placeholderText = placeholder
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = P.sub

        container.backgroundColor = P.card
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 1
        container.borderUIColor = P.border
        container.translatesAutoresizingMaskIntoConstraints = false

        counter.font = .systemFont(ofSize: 11, weight: .regular)
        counter.textColor = P.muted
        counter.setContentHuggingPriority(.required, for: .horizontal)
        counter.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = UIStackView()
        inputRow.axis = .horizontal
        inputRow.alignment = multiline ? .top : .center
        inputRow.spacing = 8
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        if let prefix {
            let p = UILabel()
            p.text = prefix
            p.font = .systemFont(ofSize: 14, weight: .regular)
            p.textColor = P.muted
            p.setContentHuggingPriority(.required, for: .horizontal)
            inputRow.addArrangedSubview(p)
        }

        if multiline {
            let tv = UITextView()
            tv.backgroundColor = .clear
            tv.font = .systemFont(ofSize: 14, weight: .regular)
            tv.textContainerInset = .zero
            tv.textContainer.lineFragmentPadding = 0
            tv.isScrollEnabled = true
            tv.delegate = self
            if value.isEmpty, let placeholder {
                tv.text = placeholder; tv.textColor = P.muted
            } else {
                tv.text = value; tv.textColor = P.text
            }
            tv.heightAnchor.constraint(equalToConstant: 60).isActive = true
            tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.textView = tv
            inputRow.addArrangedSubview(tv)
        } else {
            let tf = UITextField()
            tf.font = .systemFont(ofSize: 14, weight: .regular)
            tf.textColor = P.text
            tf.text = value
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
            if let placeholder {
                tf.attributedPlaceholder = NSAttributedString(string: placeholder,
                    attributes: [.foregroundColor: P.muted,
                                 .font: UIFont.systemFont(ofSize: 14, weight: .regular)])
            }
            tf.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
            tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
            self.textField = tf
            inputRow.addArrangedSubview(tf)
        }
        inputRow.addArrangedSubview(counter)

        container.addSubview(inputRow)
        NSLayoutConstraint.activate([
            inputRow.topAnchor.constraint(equalTo: container.topAnchor, constant: multiline ? 14 : 12),
            inputRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: multiline ? -14 : -12),
            inputRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            inputRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            multiline ? counter.topAnchor.constraint(equalTo: inputRow.topAnchor) : counter.centerYAnchor.constraint(equalTo: inputRow.centerYAnchor),
        ])

        helperLabel.font = .systemFont(ofSize: 11, weight: .regular)
        helperLabel.textColor = P.muted
        helperLabel.numberOfLines = 0

        let col = UIStackView(arrangedSubviews: [titleLabel, container, helperLabel])
        col.axis = .vertical; col.spacing = 7
        col.translatesAutoresizingMaskIntoConstraints = false
        addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: topAnchor),
            col.bottomAnchor.constraint(equalTo: bottomAnchor),
            col.leadingAnchor.constraint(equalTo: leadingAnchor),
            col.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        updateCounter()
        setHelper(error: nil)
        if helperText == nil { helperLabel.isHidden = true }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func editingChanged() {
        enforceLimit()
        updateCounter()
        onChange?()
    }

    private func enforceLimit() {
        if let tf = textField, let t = tf.text, t.count > maxLen {
            tf.text = String(t.prefix(maxLen))
        }
    }

    private func updateCounter() { counter.text = "\(text.count)/\(maxLen)" }

    private func setHelper(error: String?) {
        if let error {
            helperLabel.isHidden = false
            helperLabel.text = error
            helperLabel.textColor = P.red
            container.borderUIColor = P.red
        } else {
            helperLabel.text = helperText
            helperLabel.textColor = P.muted
            helperLabel.isHidden = (helperText == nil)
            container.borderUIColor = P.border
        }
    }

    /// Trả về true nếu hợp lệ; cập nhật giao diện lỗi.
    @discardableResult
    func validate() -> Bool {
        let err = validator(text)
        setHelper(error: err)
        return err == nil
    }
}

extension EditField: UITextViewDelegate {
    func textViewDidBeginEditing(_ tv: UITextView) {
        if tv.textColor == EditProfileViewController.P.muted {
            tv.text = ""; tv.textColor = EditProfileViewController.P.text
        }
    }
    func textViewDidEndEditing(_ tv: UITextView) {
        if tv.text.isEmpty, let ph = placeholderText {
            tv.text = ph; tv.textColor = EditProfileViewController.P.muted
        }
    }
    func textViewDidChange(_ tv: UITextView) {
        if tv.text.count > maxLen { tv.text = String(tv.text.prefix(maxLen)) }
        updateCounter()
        onChange?()
    }
}
