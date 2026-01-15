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
  func readAll(query: TodoQuery, useCache: Bool) async throws -> [Todo]
}

// MARK: - StubTodoRepository

public final class StubTodoRepository: TodoRepository, Sendable {
  public init() {}
  public func create(_: Todo) async throws {}
  public func update(_: Todo) async throws {}
  public func delete(_: String) async throws {}
  public func readAll(query _: TodoQuery, useCache _: Bool) async throws -> [Todo] { [] }
}
