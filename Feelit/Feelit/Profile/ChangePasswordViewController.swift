import UIKit

// MARK: - ChangePasswordViewController
/// Màn đổi mật khẩu (Figma 600-26281 default / 600-26296 lỗi): 3 ô mật khẩu (hiện tại,
/// mới, xác nhận) + nút "Tiếp tục" chỉ bật khi hợp lệ. Hỗ trợ light & dark qua Theme.
final class ChangePasswordViewController: UIViewController {

    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var continueButton: UIButton!

    private let currentField = PasswordField(title: "Nhập mật khẩu hiện tại")
    private let newField = PasswordField(title: "Nhập mật khẩu mới")
    private let confirmField = PasswordField(title: "Xác nhận mật khẩu mới")
    private var fields: [PasswordField] { [currentField, newField, confirmField] }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.page
        setupHeader()
        setupScroll()
        buildContent()
        fields.forEach { $0.onChange = { [weak self] in self?.revalidate() } }
        revalidate()
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
        scroll.keyboardDismissMode = .interactive
        scroll.contentInset.bottom = 40
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])
    }

    private func buildContent() {
        stack.addArrangedSubview(currentField)
        stack.addArrangedSubview(newField)
        stack.addArrangedSubview(confirmField)

        var cfg = UIButton.Configuration.filled()
        cfg.cornerStyle = .capsule
        cfg.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        continueButton = UIButton(configuration: cfg)
        continueButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        stack.addArrangedSubview(continueButton)
        stack.setCustomSpacing(8, after: confirmField)
    }

    private func revalidate() {
        // Đánh dấu lỗi cho từng ô đã nhập.
        let curOK = currentField.text.count >= 8
        currentField.setError(currentField.text.isEmpty ? nil : (curOK ? nil : "Mật khẩu chưa hợp lệ"))

        let newOK = newField.text.count >= 8
        newField.setError(newField.text.isEmpty ? nil : (newOK ? nil : "Mật khẩu chưa hợp lệ"))

        let confirmOK = !confirmField.text.isEmpty && confirmField.text == newField.text
        confirmField.setError(confirmField.text.isEmpty ? nil :
            (confirmOK ? nil : "Mật khẩu xác nhận không khớp"))

        let allValid = curOK && newOK && confirmOK
        var c = continueButton.configuration
        c?.baseBackgroundColor = allValid ? Theme.green : Theme.track
        c?.attributedTitle = AttributedString("Tiếp tục", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                                 .foregroundColor: allValid ? Theme.onAccent : Theme.textTertiary]))
        continueButton.configuration = c
        continueButton.isEnabled = allValid
    }

    @objc private func submit() {
        guard continueButton.isEnabled else { return }
        view.endEditing(true)
        let alert = UIAlertController(title: "Đã đổi mật khẩu",
            message: "Mật khẩu của bạn đã được cập nhật thành công.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - PasswordField
/// Ô nhập mật khẩu bảo mật: nhãn + ô (viền xám khi rỗng, xanh khi có nội dung,
/// đỏ khi lỗi) + dòng lỗi đỏ bên dưới.
final class PasswordField: UIView {

    var onChange: (() -> Void)?
    var text: String { field.text ?? "" }

    private let field = UITextField()
    private let container = ThemeCardView()
    private let errorLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = Theme.textPrimary

        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 1
        container.borderUIColor = Theme.borderStrong
        container.translatesAutoresizingMaskIntoConstraints = false

        field.isSecureTextEntry = true
        field.font = .systemFont(ofSize: 14, weight: .regular)
        field.textColor = Theme.textPrimary
        field.tintColor = Theme.green
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        container.addSubview(field)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 54),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        errorLabel.font = .systemFont(ofSize: 14, weight: .regular)
        errorLabel.textColor = Theme.red
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let col = UIStackView(arrangedSubviews: [titleLabel, container, errorLabel])
        col.axis = .vertical; col.spacing = 8
        col.translatesAutoresizingMaskIntoConstraints = false
        addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: topAnchor),
            col.bottomAnchor.constraint(equalTo: bottomAnchor),
            col.leadingAnchor.constraint(equalTo: leadingAnchor),
            col.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func editingChanged() {
        // Có nội dung → viền xanh; rỗng → viền xám.
        container.borderUIColor = text.isEmpty ? Theme.borderStrong : Theme.green
        onChange?()
    }

    func setError(_ message: String?) {
        if let message {
            errorLabel.text = message
            errorLabel.isHidden = false
            container.borderUIColor = Theme.red
        } else {
            errorLabel.isHidden = true
            container.borderUIColor = text.isEmpty ? Theme.borderStrong : Theme.green
        }
    }
}
