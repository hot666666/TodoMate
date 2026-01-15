//
//  CreateMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

public protocol CreateMessageUseCase {
  func run(for userId: String, _ message: GroupMessage) throws
}

public final class CreateMessageUseCaseImpl: CreateMessageUseCase {
  private let repository: MessageRepository

  public init(repository: MessageRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ message: GroupMessage) throws {
    // 1. Verify user is sender
    guard message.owner == userId else {
      throw MessageUseCaseError.userNotAuthorized
    }

    try repository.create(message)
  }
}

public final class StubCreateMessageUseCase: CreateMessageUseCase {
  public init() {}
  public func run(for _: String, _ message: GroupMessage) throws {
    try StubMessageRepository().create(message)
  }
}
