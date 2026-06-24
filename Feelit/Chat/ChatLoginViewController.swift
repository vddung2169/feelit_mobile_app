import UIKit

// MARK: - ChatLoginViewController
/// Nhập ID của mình + ID người muốn chat, validate rồi push sang ChatViewController.
final class ChatLoginViewController: UIViewController {

    private let viewModel = ChatLoginViewModel()

    // MARK: - UI
    private let myIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = L10n.Chat.myIdPlaceholder
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .next
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let partnerIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = L10n.Chat.partnerIdPlaceholder
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(L10n.Chat.startChat, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "Chỉ chấp nhận: test01 hoặc test02"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"
        view.backgroundColor = .systemBackground

        // Nhớ ID lần trước
        myIdField.text = viewModel.savedMyId

        setupLayout()

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        myIdField.delegate = self
        partnerIdField.delegate = self
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [myIdField, partnerIdField, startButton, hintLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions
    @objc private func startTapped() {
        switch viewModel.validate(myId: myIdField.text ?? "", partnerId: partnerIdField.text ?? "") {
        case .ok(let myId, let partnerId):
            let chatVC = ChatViewController(myId: myId, partnerId: partnerId)
            navigationController?.pushViewController(chatVC, animated: true)
        case .invalid:
            showAlert(L10n.Chat.invalidId)
        case .same:
            showAlert(L10n.Chat.sameId)
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: L10n.Common.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ChatLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == myIdField {
            partnerIdField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            startTapped()
        }
        return true
    }
}
