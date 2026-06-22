import Foundation
import Combine

final class AuthViewModel {

    // MARK: - Output
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentUser: UserDTO?
    @Published private(set) var pendingUserId: String?     // userId chờ verify OTP
    @Published private(set) var otpChannel: String?         // "email" | "sms"
    @Published private(set) var didCompleteAuth = false     // true → navigate to main app
    @Published private(set) var resendCooldown: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var resendTimer: AnyCancellable?

    init() {}

    /// Khởi tạo sẵn state chờ-OTP — dùng khi chuyển sang màn OTP / đặt lại mật khẩu,
    /// nơi `userId` đã có từ bước trước (register / forgot-password).
    convenience init(pendingUserId: String, otpChannel: String) {
        self.init()
        self.pendingUserId = pendingUserId
        self.otpChannel = otpChannel
    }

    // MARK: - Register
    func register(email: String?, phone: String?, password: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.register(email: email, phone: phone, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let res):
                    self?.pendingUserId = res.userId
                    self?.otpChannel = email != nil ? "email" : "sms"
                    self?.startResendCooldown(seconds: 60)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Verify OTP
    func verifyOTP(code: String) {
        guard let userId = pendingUserId, let channel = otpChannel else { return }
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.verifyOTP(userId: userId, code: code, channel: channel) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let session):
                    self?.currentUser = session.user
                    self?.didCompleteAuth = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func resendOTP() {
        guard let userId = pendingUserId, let channel = otpChannel, resendCooldown == 0 else { return }
        AuthAPIClient.shared.resendOTP(userId: userId, channel: channel) { [weak self] result in
            DispatchQueue.main.async {
                if case .success = result {
                    self?.startResendCooldown(seconds: 60)
                } else if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func startResendCooldown(seconds: Int) {
        resendCooldown = seconds
        resendTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.resendCooldown > 0 { self.resendCooldown -= 1 }
                else { self.resendTimer?.cancel() }
            }
    }

    // MARK: - Login
    func login(emailOrPhone: String, password: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.login(emailOrPhone: emailOrPhone, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let session):
                    self?.currentUser = session.user
                    self?.didCompleteAuth = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Forgot / Reset password
    func forgotPassword(emailOrPhone: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.forgotPassword(emailOrPhone: emailOrPhone) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let res):
                    self?.pendingUserId = res.userId
                    self?.otpChannel = res.channel
                    self?.startResendCooldown(seconds: 60)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func resetPassword(code: String, newPassword: String) {
        guard let userId = pendingUserId else { return }
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.resetPassword(userId: userId, code: code, newPassword: newPassword) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.didCompleteAuth = true   // → quay về login
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Logout
    func logout() {
        AuthAPIClient.shared.logout { _ in }   // best-effort, vẫn clear local
        currentUser = nil
        didCompleteAuth = false
    }

    func clearError() { errorMessage = nil }
}
