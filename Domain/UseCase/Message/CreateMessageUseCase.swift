//
//  CreateMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

protocol CreateMessageUseCase {
  func run(for userId: String, _ message: GroupMessage) throws
}

final class CreateMessageUseCaseImpl: CreateMessageUseCase {
  private let repository: MessageRepository

  init(repository: MessageRepository) {
    self.repository = repository
  }

  func run(for userId: String, _ message: GroupMessage) throws {
    guard message.owner == userId else { throw MessageUseCaseError.userNotAuthorized }
    try repository.create(message)
  }
}

final class StubCreateMessageUseCase: CreateMessageUseCase {
  func run(for _: String, _ message: GroupMessage) throws {
    try StubMessageRepository().create(message)
  }
}
