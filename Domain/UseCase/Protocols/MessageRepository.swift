//
//  MessageRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol MessageRepository {
  func create(_ message: GroupMessage) throws
  func update(_ message: GroupMessage) throws
  func delete(_ messageId: String) async throws
  func readAll(groupId: String, source: DataSource) async throws -> [GroupMessage]
  func observeAll(groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>>
}
