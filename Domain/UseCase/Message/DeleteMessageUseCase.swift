//
//  DeleteMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

protocol DeleteMessageUseCase {
  func run(for userId: String, _ message: GroupMessage) async throws
}

final class DeleteMessageUseCaseImpl: DeleteMessageUseCase {
  private let repository: MessageRepository

  init(repository: MessageRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ message: GroupMessage) async throws {
    guard message.owner == userId else { throw MessageUseCaseError.userNotAuthorized }
    try await repository.delete(message.id)
  }
}

final class StubDeleteMessageUseCase: DeleteMessageUseCase {
  func run(for _: String, _: GroupMessage) async throws {}
}
