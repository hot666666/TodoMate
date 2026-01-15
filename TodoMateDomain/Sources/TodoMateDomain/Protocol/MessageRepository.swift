//
//  MessageRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol MessageRepository {
  func create(_ message: GroupMessage) throws
  func update(_ message: GroupMessage) throws
  func delete(_ messageId: String) async throws
  func readAll(groupId: String, useCache: Bool) async throws -> [GroupMessage]
  func observeAll(groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>>
}

// MARK: - StubMessageRepository

public final class StubMessageRepository: MessageRepository, Sendable {
  public let messagesToReturn: [GroupMessage]

  public init(messagesToReturn: [GroupMessage] = []) {
    self.messagesToReturn = messagesToReturn
  }

  public func create(_: GroupMessage) throws {}
  public func update(_: GroupMessage) throws {}
  public func delete(_: String) async throws {}
  public func readAll(groupId _: String, useCache _: Bool) async throws -> [GroupMessage] {
    messagesToReturn
  }

  public func observeAll(groupId _: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    AsyncStream { continuation in
      for message in messagesToReturn {
        continuation.yield(.added(message))
      }
      // Keep stream alive
    }
  }
}
