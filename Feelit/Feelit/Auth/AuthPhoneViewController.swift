import UIKit

// MARK: - AuthPhoneViewController
/// Màn nhập số điện thoại (Figma node 161-15546). Cùng bố cục + hiệu ứng bàn phím
/// với màn email. Chip mã quốc gia bên trái mở picker; validate theo từng quốc gia.
final class AuthPhoneViewController: AuthFormViewController {

    private let isRegister: Bool
    private var country = Countries.default

    init(isRegister: Bool) {
        self.isRegister = isRegister
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
        phoneField.attributedPlaceholder = placeholder("Nhập số điện thoại")
        installField(phoneField)
        updateChipTitle()
    }

    override var isComplete: Bool {
        country.isValid(phoneField.text ?? "")
    }

    override func didTapContinue() {
        view.endEditing(true)
        let national = country.nationalDigits(phoneField.text ?? "")
        let apiPhone = "\(country.dialCode)\(national)"     // E.164 cho API: "+84987654321"
        let display  = "\(country.dialCode) \(national)"    // bản hiển thị: "+84 987654321"
        navigationController?.pushViewController(
            AuthPasswordViewController(contact: apiPhone, displayContact: display,
                                       channel: "sms", isRegister: isRegister),
            animated: true)
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
