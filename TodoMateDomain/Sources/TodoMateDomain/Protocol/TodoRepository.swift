//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol TodoRepository: Sendable {
  func create(_ todo: Todo) async throws
  func update(_ todo: Todo) async throws
  func delete(_ todoId: String) async throws
  func read(id: String) async throws -> Todo?
  func readAll(query: TodoQuery, useCache: Bool) async throws -> [Todo]
  func fetchCount(query: TodoQuery) async throws -> Int
  func observeTodos(query: TodoQuery) -> AsyncStream<[Todo]>
}

// MARK: - StubTodoRepository

public final class StubTodoRepository: TodoRepository, Sendable {
  public init() {}
  public func create(_: Todo) async throws {}
  public func update(_: Todo) async throws {}
  public func delete(_: String) async throws {}
  public func read(id _: String) async throws -> Todo? { nil }
  public func readAll(query _: TodoQuery, useCache _: Bool) async throws -> [Todo] { [] }
  public func fetchCount(query _: TodoQuery) async throws -> Int { 0 }
  public func observeTodos(query _: TodoQuery) -> AsyncStream<[Todo]> {
    AsyncStream { $0.finish() }
  }
}
