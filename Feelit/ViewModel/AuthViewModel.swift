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
    @Published private(set) var registrationUserId: String?  // userId của bản nháp đăng ký
    @Published private(set) var registrationOTPVerified = false

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

    // MARK: - Đăng ký nhiều bước
    /// Bước 1: gửi OTP tới email/SĐT (tạo bản nháp). Thành công → `registrationUserId`.
    func sendRegistrationOTP(email: String?, phone: String?) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.sendRegistrationOTP(email: email, phone: phone) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let res):
                    self?.registrationUserId = res.userId
                    self?.otpChannel = email != nil ? "email" : "sms"
                    self?.startResendCooldown(seconds: 60)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Bước 2: xác minh OTP của bản nháp (không đăng nhập). Thành công → `registrationOTPVerified`.
    func verifyRegistrationOTP(userId: String, code: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.verifyRegistrationOTP(userId: userId, code: code) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.registrationOTPVerified = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Gửi lại OTP cho bản nháp đăng ký.
    func resendRegistrationOTP(email: String?, phone: String?) {
        guard resendCooldown == 0 else { return }
        AuthAPIClient.shared.sendRegistrationOTP(email: email, phone: phone) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    self?.registrationUserId = res.userId
                    self?.startResendCooldown(seconds: 60)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Bước cuối: gắn contact bổ sung + mật khẩu, tạo tài khoản. Thành công → `didCompleteAuth`.
    func completeRegistration(userId: String, email: String?, phone: String?, password: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.completeRegistration(userId: userId, email: email, phone: phone,
                                                  password: password) { [weak self] result in
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

    // MARK: - Đăng nhập bằng SĐT qua OTP
    /// Gửi OTP đăng nhập tới SĐT. Thành công → `pendingUserId` (để màn OTP dùng).
    func sendPhoneLoginOTP(phone: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.sendLoginOTP(phone: phone) { [weak self] result in
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

    /// Xác minh OTP đăng nhập → lưu session, `didCompleteAuth`.
    func verifyPhoneLoginOTP(userId: String, code: String) {
        isLoading = true
        errorMessage = nil
        AuthAPIClient.shared.verifyLoginOTP(userId: userId, code: code) { [weak self] result in
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
