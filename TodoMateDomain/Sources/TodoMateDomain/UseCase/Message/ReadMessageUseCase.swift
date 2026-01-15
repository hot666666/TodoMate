//
//  ReadMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

public protocol ReadMessageUseCase {
  func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage]
}

public final class ReadMessageUseCaseImpl: ReadMessageUseCase {
  private let repository: MessageRepository

  public init(repository: MessageRepository) {
    self.repository = repository
  }

  public func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage] {
    try await repository.readAll(groupId: groupId, useCache: useCache)
  }
}

public final class StubReadMessageUseCase: ReadMessageUseCase {
  public init() {}
  public func run(in groupId: String, useCache: Bool) async throws -> [GroupMessage] {
    try await StubMessageRepository().readAll(groupId: groupId, useCache: useCache)
  }
}
