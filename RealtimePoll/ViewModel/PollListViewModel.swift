import Foundation
import Combine

// MARK: - PollListViewModel
/// Logic cho `MainViewController`: tải danh sách poll, tạo poll, điều hướng.
/// KHÔNG import UIKit, không biết ViewController tồn tại.
final class PollListViewModel {

    // MARK: - Output
    @Published private(set) var polls: [Poll] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil          // lỗi tải danh sách
    @Published private(set) var createPollError: String? = nil       // lỗi tạo poll (tách riêng để hiển thị alert)
    @Published private(set) var isCreatingPoll = false
    @Published private(set) var navigateToPoll: Poll? = nil          // nil → không navigate

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Input
    func loadPolls() {
        isLoading = true
        getPollsPublisher()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let err) = completion {
                        self?.errorMessage = err.localizedDescription
                    }
                },
                receiveValue: { [weak self] polls in
                    self?.errorMessage = nil
                    self?.polls = polls
                }
            )
            .store(in: &cancellables)
    }

    func createPoll(title: String) {
        isCreatingPoll = true
        createPollPublisher(title: title)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isCreatingPoll = false
                    if case .failure(let err) = completion {
                        self?.createPollError = err.localizedDescription
                    }
                },
                receiveValue: { [weak self] poll in
                    self?.navigateToPoll = poll
                }
            )
            .store(in: &cancellables)
    }

    func loadActivePoll() {
        isLoading = true
        Future<Poll, Error> { promise in
            PollRepository.shared.loadActivePoll { promise($0) }
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            },
            receiveValue: { [weak self] poll in self?.navigateToPoll = poll }
        )
        .store(in: &cancellables)
    }

    func createDemoPoll() {
        isCreatingPoll = true
        Future<Poll, Error> { promise in
            PollRepository.shared.createDemoPoll { promise($0) }
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isCreatingPoll = false
                if case .failure(let err) = completion {
                    self?.createPollError = err.localizedDescription
                }
            },
            receiveValue: { [weak self] poll in self?.navigateToPoll = poll }
        )
        .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
        createPollError = nil
    }

    func clearNavigation() { navigateToPoll = nil }

    // MARK: - Publishers (wrap completion → Combine)
    private func getPollsPublisher() -> AnyPublisher<[Poll], Error> {
        Future { promise in
            APIClient.shared.getPolls { promise($0) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    private func createPollPublisher(title: String) -> AnyPublisher<Poll, Error> {
        Future { promise in
            APIClient.shared.createPoll(title: title) { promise($0) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    deinit { cancellables.removeAll() }
}
