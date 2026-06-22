import Foundation

// MARK: - AuthAPIClient
/// REST client cho Identity & Profile domain.
/// Tự đính `Authorization: Bearer {accessToken}` header và tự refresh token khi 401.
final class AuthAPIClient {
    static let shared = AuthAPIClient()
    private init() {}

    #if DEBUG
    private let baseURL = "http://localhost:3001"
    #else
    private let baseURL = "https://api.feelit.vn"
    #endif

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder = JSONEncoder()

    // MARK: - Public endpoints (không cần token)

    func register(email: String?, phone: String?, password: String,
                  completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        let body = RegisterRequest(email: email, phone: phone, password: password)
        post("/api/auth/register", body: body, completion: completion)
    }

    func verifyOTP(userId: String, code: String, channel: String,
                   completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        let body = VerifyOTPRequest(userId: userId, code: code, channel: channel)
        post("/api/auth/verify-otp", body: body) { (result: Result<AuthSessionResponse, Error>) in
            if case .success(let session) = result {
                TokenStore.shared.saveSession(session)
            }
            completion(result)
        }
    }

    func resendOTP(userId: String, channel: String,
                   completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let body = ["userId": userId, "channel": channel]
        post("/api/auth/resend-otp", body: body, completion: completion)
    }

    func login(emailOrPhone: String, password: String,
               completion: @escaping (Result<AuthSessionResponse, Error>) -> Void) {
        let body = LoginRequest(emailOrPhone: emailOrPhone, password: password)
        post("/api/auth/login", body: body) { (result: Result<AuthSessionResponse, Error>) in
            if case .success(let session) = result {
                TokenStore.shared.saveSession(session)
            }
            completion(result)
        }
    }

    func forgotPassword(emailOrPhone: String,
                        completion: @escaping (Result<ForgotPasswordResponse, Error>) -> Void) {
        let body = ForgotPasswordRequest(emailOrPhone: emailOrPhone)
        post("/api/auth/forgot-password", body: body, completion: completion)
    }

    func resetPassword(userId: String, code: String, newPassword: String,
                       completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let body = ResetPasswordRequest(userId: userId, code: code, newPassword: newPassword)
        post("/api/auth/reset-password", body: body, completion: completion)
    }

    func logout(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        guard let refreshToken = TokenStore.shared.refreshToken else {
            TokenStore.shared.clearSession()
            completion(.success(EmptyResponse()))
            return
        }
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        authorizedPost("/api/auth/logout", body: body) { (result: Result<EmptyResponse, Error>) in
            TokenStore.shared.clearSession()
            completion(result)
        }
    }

    // MARK: - Authorized endpoints (cần token, tự refresh khi 401)

    func getCurrentUser(completion: @escaping (Result<UserDTO, Error>) -> Void) {
        authorizedGet("/api/users/me", completion: completion)
    }

    func updateProfile(username: String? = nil, displayName: String? = nil,
                       bio: String? = nil, avatarUrl: String? = nil,
                       completion: @escaping (Result<UserDTO, Error>) -> Void) {
        var body: [String: String] = [:]
        if let username { body["username"] = username }
        if let displayName { body["displayName"] = displayName }
        if let bio { body["bio"] = bio }
        if let avatarUrl { body["avatarUrl"] = avatarUrl }
        authorizedRequest(path: "/api/users/me", method: "PATCH", body: body, completion: completion)
    }

    // MARK: - Private helpers

    private func post<Body: Encodable, T: Decodable>(
        _ path: String, body: Body,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(path: path, method: "POST", body: body, requiresAuth: false, completion: completion)
    }

    private func authorizedGet<T: Decodable>(
        _ path: String, completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(path: path, method: "GET", body: Optional<EmptyBody>.none,
                requiresAuth: true, completion: completion)
    }

    private func authorizedPost<Body: Encodable, T: Decodable>(
        _ path: String, body: Body,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(path: path, method: "POST", body: body, requiresAuth: true, completion: completion)
    }

    private func authorizedRequest<T: Decodable>(
        path: String, method: String, body: [String: String],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        request(path: path, method: method, body: body, requiresAuth: true, completion: completion)
    }

    /// Generic request — tự đính Authorization header, tự refresh token 1 lần nếu 401.
    private func request<Body: Encodable, T: Decodable>(
        path: String, method: String, body: Body?, requiresAuth: Bool,
        retryAfterRefresh: Bool = true,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(URLError(.badURL))); return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10

        if requiresAuth, let token = TokenStore.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body, !(body is EmptyBody) {
            req.httpBody = try? encoder.encode(body)
        }

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            if let error { completion(.failure(error)); return }
            guard let data, let http = response as? HTTPURLResponse else {
                completion(.failure(URLError(.zeroByteResource))); return
            }

            // Token hết hạn → tự refresh rồi retry 1 lần
            if http.statusCode == 401, requiresAuth, retryAfterRefresh {
                self.refreshTokenAndRetry {
                    self.request(path: path, method: method, body: body, requiresAuth: requiresAuth,
                                 retryAfterRefresh: false, completion: completion)
                }
                return
            }

            if http.statusCode >= 400 {
                if let apiError = try? self.decoder.decode(APIErrorBody.self, from: data) {
                    completion(.failure(AuthError.from(errorCode: apiError.error)))
                } else {
                    completion(.failure(URLError(.init(rawValue: http.statusCode))))
                }
                return
            }

            // 204 No Content
            if data.isEmpty, let empty = EmptyResponse() as? T {
                completion(.success(empty)); return
            }

            do {
                let decoded = try self.decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func refreshTokenAndRetry(_ onSuccess: @escaping () -> Void) {
        guard let refreshToken = TokenStore.shared.refreshToken else {
            TokenStore.shared.clearSession()
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            return
        }
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        post("/api/auth/refresh", body: body) { (result: Result<RefreshTokenResponse, Error>) in
            switch result {
            case .success(let tokens):
                TokenStore.shared.accessToken = tokens.accessToken
                TokenStore.shared.refreshToken = tokens.refreshToken
                onSuccess()
            case .failure:
                TokenStore.shared.clearSession()
                NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            }
        }
    }
}

struct EmptyBody: Codable {}
struct EmptyResponse: Codable {}
private struct APIErrorBody: Codable { let error: String }

extension Notification.Name {
    /// Post khi refresh token cũng hết hạn — App phải show lại màn login.
    static let authSessionExpired = Notification.Name("authSessionExpired")
}
