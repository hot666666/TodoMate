//
//  UpdateMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

public protocol UpdateMessageUseCase {
  func run(for userId: String, _ message: GroupMessage) throws
}

public final class UpdateMessageUseCaseImpl: UpdateMessageUseCase {
  private let repository: MessageRepository

  public init(repository: MessageRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ message: GroupMessage) throws {
    guard message.owner == userId else { throw MessageUseCaseError.userNotAuthorized }
    try repository.update(message)
  }
}

public final class StubUpdateMessageUseCase: UpdateMessageUseCase {
  public init() {}
  public func run(for _: String, _ message: GroupMessage) throws {
    try StubMessageRepository().update(message)
  }
}
