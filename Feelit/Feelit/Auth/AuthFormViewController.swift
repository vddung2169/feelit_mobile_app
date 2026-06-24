import UIKit

// MARK: - AuthFormViewController
/// Khung dùng chung cho các bước nhập liệu của flow Auth (email, mật khẩu...).
/// Cung cấp: nút "Trở lại", tiêu đề, ô nhập, dòng điều khoản, nút "Tiếp tục",
/// và toàn bộ hiệu ứng bàn phím (nhóm tiêu đề căn giữa ↔ trượt lên đỉnh, nút nổi
/// trên bàn phím). Subclass chỉ cần khai báo tiêu đề, dựng ô nhập và điều kiện hợp lệ.
class AuthFormViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: - Điểm override cho subclass
    /// Tiêu đề lớn của bước.
    var formTitle: String { "" }
    /// Nhãn nút chính.
    var continueButtonTitle: String { L10n.Auth.continueButton }
    /// Các view phụ hiển thị ngay dưới ô nhập (link / hint...).
    var headAccessoryViews: [UIView] { [] }
    /// View chiếm vị trí "hàng ô nhập" trong nhóm tiêu đề. Mặc định là `fieldContainer`;
    /// override để bọc thêm (vd: chip mã quốc gia bên trái ô nhập SĐT).
    var fieldRow: UIView { fieldContainer }
    /// Điều kiện hợp lệ để bật nút "Tiếp tục".
    var isComplete: Bool { false }

    /// Subclass dựng nội dung bên trong `fieldContainer` (thường gọi `installField`).
    func makeFieldContent() {}
    /// Hành động khi bấm "Tiếp tục" lúc đã hợp lệ.
    func didTapContinue() {}
    /// Gọi mỗi khi text thay đổi. Override để cập nhật thêm (hint...) và nhớ gọi `super`.
    func fieldDidChange() { refreshContinueState() }

    /// Ô nhập chính (do subclass gán qua `installField`) — dùng cho focus/return.
    private(set) var primaryField: UITextField?

    // MARK: - UI dùng chung
    let fieldContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AuthTheme.inputField
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = AuthTheme.fieldBorder.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePadding = 4
        config.attributedTitle = AttributedString(L10n.Auth.backButton, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 17, weight: .regular)]))
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = formTitle
        l.font = FeelitFonts.rounded(30, weight: .bold)
        l.textColor = AuthTheme.textPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let termsLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var continueButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(continueButtonTitle, attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]))
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return b
    }()

    // Toggle bố cục nhóm tiêu đề: căn giữa (mặc định) ↔ sát đỉnh (khi có bàn phím).
    private var headCenterConstraint: NSLayoutConstraint!
    private var headTopConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        termsLabel.attributedText = makeTermsText()

        makeFieldContent()
        setupLayout()
        refreshContinueState()

        // Chạm vào ô → focus; chạm nền → ẩn bàn phím.
        fieldContainer.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(focusField)))
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        bgTap.cancelsTouchesInView = false
        bgTap.delegate = self
        view.addGestureRecognizer(bgTap)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupLayout() {
        // Nhóm tiêu đề: tiêu đề → hàng ô nhập → (view phụ).
        let row = fieldRow
        let head = UIStackView(arrangedSubviews: [titleLabel, row] + headAccessoryViews)
        head.axis = .vertical
        head.alignment = .fill
        head.spacing = 16
        head.setCustomSpacing(28, after: titleLabel)
        head.setCustomSpacing(18, after: row)
        head.translatesAutoresizingMaskIntoConstraints = false

        // Khối đáy: điều khoản + nút Tiếp tục, nổi trên bàn phím.
        let bottom = UIStackView(arrangedSubviews: [termsLabel, continueButton])
        bottom.axis = .vertical
        bottom.alignment = .fill
        bottom.spacing = 16
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backButton)
        view.addSubview(head)
        view.addSubview(bottom)

        headCenterConstraint = head.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)
        headTopConstraint = head.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24)
        headCenterConstraint.isActive = true

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            head.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            head.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            head.topAnchor.constraint(greaterThanOrEqualTo: backButton.bottomAnchor, constant: 16),

            fieldContainer.heightAnchor.constraint(equalToConstant: 56),

            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottom.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16),

            continueButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    // MARK: - Helper dựng ô nhập
    /// Gắn `field` vào `fieldContainer` với style/constraint chuẩn và đăng ký theo dõi.
    /// `trailingInset` nới ra khi có phụ kiện bên phải (vd nút con mắt).
    func installField(_ field: UITextField, trailingInset: CGFloat = 18) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.textColor = AuthTheme.textPrimary
        field.tintColor = AuthTheme.green
        field.returnKeyType = .continue
        fieldContainer.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 18),
            field.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -trailingInset),
            field.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
        ])
        field.addTarget(self, action: #selector(editingChangedAction), for: .editingChanged)
        field.delegate = self
        primaryField = field
    }

    /// Placeholder theo style chuẩn (chữ xám nhạt).
    func placeholder(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.foregroundColor: AuthTheme.placeholder])
    }

    /// Đang gọi API → nút hiện spinner và bị khoá.
    private(set) var isBusy = false

    /// Bật/tắt spinner trên nút "Tiếp tục" khi gọi API.
    func setLoading(_ loading: Bool) {
        isBusy = loading
        var config = continueButton.configuration
        config?.showsActivityIndicator = loading
        continueButton.configuration = config
        refreshContinueState()
    }

    // MARK: - Trạng thái nút
    func refreshContinueState() {
        var config = continueButton.configuration
        let enabled = isComplete && !isBusy
        config?.baseBackgroundColor = enabled ? AuthTheme.green : AuthTheme.buttonDisabled
        config?.baseForegroundColor = enabled ? AuthTheme.onGreen : AuthTheme.placeholder
        continueButton.configuration = config
        continueButton.isEnabled = enabled
        // Viền ô chuyển xanh khi hợp lệ.
        fieldContainer.layer.borderColor =
            (enabled ? AuthTheme.fieldBorderActive : AuthTheme.fieldBorder).cgColor
    }

    @objc private func editingChangedAction() { fieldDidChange() }

    // MARK: - Điều khoản
    private func makeTermsText() -> NSAttributedString {
        let base = L10n.Auth.termsText
        let s = NSMutableAttributedString(string: base, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: AuthTheme.textTertiary,
        ])
        let bold: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: AuthTheme.textSecondary,
        ]
        for phrase in ["Điều khoản Dịch vụ", "Chính sách Bảo mật"] {
            let r = (base as NSString).range(of: phrase)
            if r.location != NSNotFound { s.addAttributes(bold, range: r) }
        }
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 2
        s.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: s.length))
        return s
    }

    // MARK: - Bàn phím
    @objc private func keyboardWillChange(_ note: Notification) {
        let showing = note.name == UIResponder.keyboardWillShowNotification
        headCenterConstraint.isActive = !showing
        headTopConstraint.isActive = showing

        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
        UIView.animate(withDuration: duration, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curveRaw << 16)) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Actions
    @objc private func focusField() { primaryField?.becomeFirstResponder() }
    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    @objc private func continueTapped() { attemptContinue() }

    /// Bấm nút hoặc Return → chạy tiếp nếu hợp lệ (và không đang bận gọi API).
    func attemptContinue() {
        guard isComplete, !isBusy else { return }
        didTapContinue()
    }
}

// MARK: - UITextFieldDelegate
extension AuthFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        attemptContinue()
        return false
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AuthFormViewController: UIGestureRecognizerDelegate {
    /// Tap nền chỉ để ẩn bàn phím — bỏ qua khi chạm vào control hoặc ô nhập.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        guard let touched = touch.view else { return true }
        if touched is UIControl { return false }
        if touched.isDescendant(of: fieldContainer) { return false }
        return true
    }
}
