import UIKit
import Combine

// MARK: - OTPInputView
/// 6 ô nhập mã OTP. Một `UITextField` ẩn nhận phím số (kèm tự điền OTP từ SMS),
/// hiển thị từng chữ số vào ô. Hỗ trợ trạng thái lỗi (viền đỏ).
final class OTPInputView: UIView {

    let length = 6
    var onChange: ((String) -> Void)?
    var onComplete: ((String) -> Void)?

    private let entry = UITextField()
    private var boxes: [UIView] = []
    private var labels: [UILabel] = []
    private var isError = false

    var code: String { entry.text ?? "" }

    override init(frame: CGRect) {
        super.init(frame: frame)
        entry.keyboardType = .numberPad
        entry.textContentType = .oneTimeCode
        entry.tintColor = .clear
        entry.textColor = .clear
        entry.delegate = self
        entry.addTarget(self, action: #selector(changed), for: .editingChanged)
        addSubview(entry)
        entry.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for _ in 0..<length {
            let box = UIView()
            box.backgroundColor = AuthTheme.inputField
            box.layer.cornerRadius = 12
            box.layer.borderWidth = 1
            box.layer.borderColor = AuthTheme.fieldBorder.cgColor
            let lbl = UILabel()
            lbl.font = FeelitFonts.rounded(24, weight: .semibold)
            lbl.textColor = AuthTheme.textPrimary
            lbl.textAlignment = .center
            lbl.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: box.centerYAnchor),
                box.heightAnchor.constraint(equalToConstant: 56),
            ])
            boxes.append(box); labels.append(lbl)
            stack.addArrangedSubview(box)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            entry.topAnchor.constraint(equalTo: topAnchor),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(focus)))
        update()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @discardableResult
    override func becomeFirstResponder() -> Bool { entry.becomeFirstResponder() }

    @objc private func focus() { entry.becomeFirstResponder() }

    func setError(_ error: Bool) { isError = error; update() }

    func clear() { entry.text = ""; isError = false; update() }

    @objc private func changed() {
        isError = false
        update()
        onChange?(code)
        if code.count == length { onComplete?(code) }
    }

    private func update() {
        let n = code.count
        let focused = entry.isFirstResponder
        for (i, box) in boxes.enumerated() {
            labels[i].text = i < n ? String(Array(code)[i]) : ""
            let color: UIColor
            if isError { color = AuthTheme.bad }
            else if focused && i == n { color = AuthTheme.fieldBorderActive }
            else { color = AuthTheme.otpBorder }
            box.layer.borderColor = color.cgColor
        }
    }
}

extension OTPInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let r = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: r, with: string)
        return updated.count <= length && updated.allSatisfy(\.isNumber)
    }
    func textFieldDidBeginEditing(_ textField: UITextField) { update() }
    func textFieldDidEndEditing(_ textField: UITextField) { update() }
}

// MARK: - AuthOTPViewController
/// Màn xác nhận OTP 6 số (Figma node 161-16836). Nhập đủ 6 số → xác minh;
/// sai hiển thị viền đỏ + thông báo; đúng → màn thành công. Có đếm ngược gửi lại mã.
final class AuthOTPViewController: UIViewController {

    private let contact: String      // email hoặc SĐT (đã định dạng để hiển thị)
    private let channel: String      // "email" | "sms"
    private let registrationContext: RegistrationContext?  // != nil → xác minh cho đăng ký
    private let phoneLoginUserId: String?                  // != nil → xác minh cho đăng nhập SĐT
    private let resendSeconds = 60

    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()

    /// `userId` lấy từ bước /register trước đó; `contact` chỉ để hiển thị.
    init(userId: String, contact: String, channel: String) {
        self.contact = contact
        self.channel = channel
        self.registrationContext = nil
        self.phoneLoginUserId = nil
        self.viewModel = AuthViewModel(pendingUserId: userId, otpChannel: channel)
        super.init(nibName: nil, bundle: nil)
    }
    /// Xác minh OTP cho flow đăng ký nhiều bước — verify xong sang màn nhập mật khẩu.
    init(registration context: RegistrationContext) {
        self.contact = context.email ?? context.phoneDisplay ?? ""
        self.channel = context.primaryChannel
        self.registrationContext = context
        self.phoneLoginUserId = nil
        self.viewModel = AuthViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    /// Xác minh OTP cho đăng nhập bằng SĐT — verify xong là đăng nhập luôn.
    init(phoneLoginUserId userId: String, displayPhone: String) {
        self.contact = displayPhone
        self.channel = "sms"
        self.registrationContext = nil
        self.phoneLoginUserId = userId
        self.viewModel = AuthViewModel(pendingUserId: userId, otpChannel: "sms")
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    private var remaining = 0
    private var timer: Timer?

    // MARK: UI
    private lazy var backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        config.imagePadding = 4
        config.attributedTitle = AttributedString("Trở lại", attributes:
            AttributeContainer([.font: UIFont.systemFont(ofSize: 17, weight: .regular)]))
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Xác nhận SĐT"
        l.font = FeelitFonts.rounded(26, weight: .semibold)
        l.textColor = AuthTheme.textPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let otpView = OTPInputView()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.text = "Mã bạn vừa nhập không đúng hãy thử lại nhé!"
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = AuthTheme.bad
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var resendButton: UIButton = {
        // type .custom: không chạy fade animation khi đổi title (tránh nhấp nháy mỗi giây).
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.lineBreakMode = .byClipping
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        b.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        return b
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = AuthTheme.textPrimary
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = AuthTheme.background
        titleLabel.text = channel == "email" ? "Xác nhận Email" : "Xác nhận SĐT"
        subtitleLabel.attributedText = makeSubtitle()
        otpView.translatesAutoresizingMaskIntoConstraints = false
        otpView.onChange = { [weak self] _ in self?.errorLabel.isHidden = true }
        otpView.onComplete = { [weak self] code in self?.verify(code) }
        setupLayout()
        startCountdown()
        bindViewModel()
    }

    // MARK: ViewModel binding
    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                loading ? self.spinner.startAnimating() : self.spinner.stopAnimating()
                self.otpView.isUserInteractionEnabled = !loading
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                guard let self else { return }
                self.viewModel.clearError()
                self.errorLabel.text = message
                self.errorLabel.isHidden = false
                self.otpView.setError(true)
                self.shake(self.otpView)
            }
            .store(in: &cancellables)

        // Xác minh OTP thành công → tokens đã lưu → màn thành công.
        viewModel.$didCompleteAuth
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                self.view.endEditing(true)
                // Đăng nhập bằng SĐT → vào thẳng app; flow cũ → onboarding.
                let isLogin = self.phoneLoginUserId != nil
                self.navigationController?.pushViewController(
                    AuthSuccessViewController(email: self.contact,
                                              title: "Đăng nhập thành công!",
                                              destination: isLogin ? .mainApp : .onboarding),
                    animated: true)
            }
            .store(in: &cancellables)

        // Flow đăng ký: xác minh OTP xong → sang màn nhập mật khẩu (chưa đăng nhập).
        viewModel.$registrationOTPVerified
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self, let ctx = self.registrationContext else { return }
                self.view.endEditing(true)
                self.navigationController?.pushViewController(
                    AuthPasswordViewController(registration: ctx), animated: true)
            }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        otpView.becomeFirstResponder()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, otpView, resendButton, errorLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.setCustomSpacing(12, after: titleLabel)
        stack.setCustomSpacing(36, after: subtitleLabel)
        stack.setCustomSpacing(24, after: otpView)
        stack.setCustomSpacing(16, after: resendButton)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backButton)
        view.addSubview(stack)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            stack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            otpView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            otpView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24),
        ])
    }

    // MARK: Subtitle
    private func makeSubtitle() -> NSAttributedString {
        let line1 = "Vui lòng nhập mã xác nhận được gửi qua\n"
        let s = NSMutableAttributedString(string: line1, attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: AuthTheme.textPrimary,
        ])
        let target = channel == "email" ? contact : maskedPhone()
        s.append(NSAttributedString(string: target, attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: AuthTheme.green,
        ]))
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 4
        s.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: s.length))
        return s
    }

    /// "+84 987654321" → "+84 987 *** 4321".
    private func maskedPhone() -> String {
        let parts = contact.split(separator: " ", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return contact }
        let dial = parts[0]
        let digits = parts[1].filter(\.isNumber)
        guard digits.count >= 7 else { return contact }
        let head = String(digits.prefix(3))
        let tail = String(digits.suffix(4))
        return "\(dial) \(head) *** \(tail)"
    }

    // MARK: Verify
    private func verify(_ code: String) {
        view.endEditing(true)
        if let ctx = registrationContext {
            viewModel.verifyRegistrationOTP(userId: ctx.userId, code: code)
        } else if let uid = phoneLoginUserId {
            viewModel.verifyPhoneLoginOTP(userId: uid, code: code)
        } else {
            viewModel.verifyOTP(code: code)
        }
    }

    private func shake(_ v: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-10, 10, -8, 8, -4, 4, 0]
        anim.duration = 0.4
        v.layer.add(anim, forKey: "shake")
    }

    // MARK: Countdown
    private func startCountdown() {
        remaining = resendSeconds
        updateResend()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.remaining -= 1
            self.updateResend()
            if self.remaining <= 0 { self.timer?.invalidate() }
        }
    }

    private func updateResend() {
        let counting = remaining > 0
        let title = NSMutableAttributedString(string: "Gửi lại mã", attributes: [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: counting ? AuthTheme.textSecondary : AuthTheme.green,
        ])
        if counting {
            title.append(NSAttributedString(string: String(format: "  (00:%02d)", remaining), attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: AuthTheme.green,
            ]))
        }
        UIView.performWithoutAnimation {
            resendButton.setAttributedTitle(title, for: .normal)
            resendButton.layoutIfNeeded()
        }
        resendButton.isEnabled = !counting
    }

    // MARK: Actions
    @objc private func resendTapped() {
        otpView.clear()
        errorLabel.isHidden = true
        startCountdown()
        otpView.becomeFirstResponder()
        if let ctx = registrationContext {
            viewModel.resendRegistrationOTP(email: ctx.email, phone: ctx.phone)
        } else {
            viewModel.resendOTP()   // gọi /api/auth/resend-otp
        }
    }

    @objc private func backTapped() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }

    deinit { timer?.invalidate() }
}
