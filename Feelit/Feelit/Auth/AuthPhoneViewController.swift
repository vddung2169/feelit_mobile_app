import UIKit
import Combine

// MARK: - AuthPhoneViewController
/// Màn nhập số điện thoại (Figma node 161-15546). Cùng bố cục + hiệu ứng bàn phím
/// với màn email. Chip mã quốc gia bên trái mở picker; validate theo từng quốc gia.
///
/// Ba vai trò:
///  • Đăng nhập (`isRegister == false`): nhập SĐT → màn mật khẩu.
///  • Đăng ký bước đầu (`isRegister == true`): nhập SĐT → gửi OTP → màn xác nhận.
///  • Đăng ký bước cuối (`finalContext != nil`): thu SĐT bổ sung → hoàn tất đăng ký.
final class AuthPhoneViewController: AuthFormViewController {

    private let isRegister: Bool
    private let finalContext: RegistrationContext?
    private var country = Countries.default

    private let viewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var pendingContext: RegistrationContext?
    private var pendingLoginDisplay: String?

    init(isRegister: Bool) {
        self.isRegister = isRegister
        self.finalContext = nil
        super.init(nibName: nil, bundle: nil)
    }
    /// Bước cuối của đăng ký bằng email: thu thêm SĐT rồi hoàn tất.
    init(finalRegistration context: RegistrationContext) {
        self.isRegister = true
        self.finalContext = context
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var formTitle: String { "SĐT của bạn là" }

    // MARK: Field
    private let phoneField: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .phonePad
        tf.textContentType = .telephoneNumber
        return tf
    }()

    private lazy var countryChip: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = AuthTheme.textPrimary
        config.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = AuthTheme.inputField
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1
        b.layer.borderColor = AuthTheme.fieldBorder.cgColor
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        b.addTarget(self, action: #selector(pickCountry), for: .touchUpInside)
        return b
    }()

    override var fieldRow: UIView {
        let row = UIStackView(arrangedSubviews: [countryChip, fieldContainer])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .fill
        row.distribution = .fill
        return row
    }

    override func makeFieldContent() {
        phoneField.attributedPlaceholder = placeholder(L10n.Auth.phonePlaceholder)
        installField(phoneField)
        updateChipTitle()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindIfNeeded()
    }

    override var isComplete: Bool {
        country.isValid(phoneField.text ?? "")
    }

    override func didTapContinue() {
        view.endEditing(true)
        let national = country.nationalDigits(phoneField.text ?? "")
        let apiPhone = "\(country.dialCode)\(national)"     // E.164 cho API: "+84987654321"
        let display  = "\(country.dialCode) \(national)"    // bản hiển thị: "+84 987654321"

        if let ctx = finalContext {
            // Bước cuối: gắn SĐT → sang màn OTP xác thực SĐT (mã sẽ gửi qua SMS;
            // hiện dùng mã giả lập 123456). Verify xong mới hoàn tất đăng ký.
            ctx.phone = apiPhone
            ctx.phoneDisplay = display
            navigationController?.pushViewController(
                AuthOTPViewController(finalPhoneRegistration: ctx), animated: true)
        } else if isRegister {
            // Bước đầu đăng ký bằng SĐT: gửi OTP.
            let ctx = RegistrationContext(primaryChannel: "sms")
            ctx.phone = apiPhone
            ctx.phoneDisplay = display
            pendingContext = ctx
            setLoading(true)
            viewModel.sendRegistrationOTP(email: nil, phone: apiPhone)
        } else {
            // Đăng nhập bằng SĐT: gửi OTP rồi sang màn "Xác nhận SĐT".
            pendingLoginDisplay = display
            setLoading(true)
            viewModel.sendPhoneLoginOTP(phone: apiPhone)
        }
    }

    // MARK: Binding
    private func bindIfNeeded() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.setLoading($0) }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.viewModel.clearError()
                self?.presentAlert(message)
            }
            .store(in: &cancellables)

        if finalContext != nil {
            // Bước cuối (SĐT) điều hướng thẳng sang màn OTP trong didTapContinue;
            // việc hoàn tất đăng ký + màn "Đăng ký thành công!" do màn OTP đảm nhiệm.
        } else if isRegister {
            // Đăng ký bước đầu (SĐT) → gửi OTP xong → màn xác nhận.
            viewModel.$registrationUserId
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] userId in
                    guard let self, let ctx = self.pendingContext else { return }
                    ctx.userId = userId
                    self.navigationController?.pushViewController(
                        AuthOTPViewController(registration: ctx), animated: true)
                }
                .store(in: &cancellables)
        } else {
            // Đăng nhập bằng SĐT → gửi OTP xong → màn "Xác nhận SĐT".
            viewModel.$pendingUserId
                .receive(on: DispatchQueue.main)
                .compactMap { $0 }
                .sink { [weak self] userId in
                    guard let self else { return }
                    self.navigationController?.pushViewController(
                        AuthOTPViewController(phoneLoginUserId: userId,
                                              displayPhone: self.pendingLoginDisplay ?? ""),
                        animated: true)
                }
                .store(in: &cancellables)
        }
    }

    private func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: Country chip
    private func updateChipTitle() {
        countryChip.configuration?.attributedTitle = AttributedString(
            "\(country.flag) \(country.dialCode)",
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 15, weight: .regular)]))
    }

    @objc private func pickCountry() {
        view.endEditing(true)
        let picker = CountryPickerViewController()
        picker.onSelect = { [weak self] selected in
            guard let self else { return }
            self.country = selected
            self.updateChipTitle()
            self.fieldDidChange()
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.overrideUserInterfaceStyle = .light
        present(nav, animated: true)
    }
}
