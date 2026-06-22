import Foundation
import Combine

final class ProfileViewModel {

    @Published private(set) var user: UserDTO?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

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
