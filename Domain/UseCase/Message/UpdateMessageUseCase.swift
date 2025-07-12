//
//  UpdateMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

protocol UpdateMessageUseCase {
  func run(for userId: String, _ message: GroupMessage) throws
}

final class UpdateMessageUseCaseImpl: UpdateMessageUseCase {
  private let repository: MessageRepository

  init(repository: MessageRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ message: GroupMessage) throws {
    guard message.owner == userId else { throw MessageUseCaseError.userNotAuthorized }
    try repository.update(message)
  }
}

final class StubUpdateMessageUseCase: UpdateMessageUseCase {
  func run(for _: String, _ message: GroupMessage) throws {
    try StubMessageRepository().update(message)
  }
}
