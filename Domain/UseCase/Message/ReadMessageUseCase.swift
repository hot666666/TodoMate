//
//  ReadMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

protocol ReadMessageUseCase {
  func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage]
}

final class ReadMessageUseCaseImpl: ReadMessageUseCase {
  private let repository: MessageRepository

  init(repository: MessageRepository) {
    self.repository = repository
  }

  func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage] {
    try await repository.readAll(groupId: groupId, source: useCache ? .cache : .server)
  }
}

final class StubReadMessageUseCase: ReadMessageUseCase {
  func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage] {
    try await StubMessageRepository().readAll(groupId: groupId, source: useCache ? .cache : .server)
  }
}
