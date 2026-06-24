import Foundation
import Combine

final class ProfileViewModel {

    @Published private(set) var user: UserDTO?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Presentation (mock)
    /// Dữ liệu hiển thị cho `ProfileViewController`. Hiện dùng mock; sẽ thay bằng `user` (API)
    /// khi nối backend thật. Tách tên riêng để không đụng `user: UserDTO?` ở trên.
    let profile = FEMock.user
    let activities = FEMock.activities

    func loadProfile() {
        isLoading = true
        AuthAPIClient.shared.getCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user): self?.user = user
                case .failure(let error): self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateProfile(displayName: String?, bio: String?) {
        isLoading = true
        AuthAPIClient.shared.updateProfile(displayName: displayName, bio: bio) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user): self?.user = user
                case .failure(let error): self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearError() { errorMessage = nil }
}
