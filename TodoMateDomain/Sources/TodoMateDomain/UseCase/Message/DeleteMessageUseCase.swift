//
//  DeleteMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

public protocol DeleteMessageUseCase: Sendable {
  func run(for userId: String, _ message: GroupMessage) async throws
}

public final class DeleteMessageUseCaseImpl: DeleteMessageUseCase {
  private let repository: MessageRepository

  public init(repository: MessageRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ message: GroupMessage) async throws {
    // 1. Verify ownership
    guard message.owner == userId else {
      throw MessageUseCaseError.userNotAuthorized
    }

    try await repository.delete(message.id)
  }
}

public final class StubDeleteMessageUseCase: DeleteMessageUseCase {
  public init() {}
  public func run(for _: String, _: GroupMessage) async throws {}
}
