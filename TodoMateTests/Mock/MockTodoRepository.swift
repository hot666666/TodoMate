//
//  MockTodoRepository.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import Foundation
@testable import TodoMate

struct MockTodoRepository: TodoRepositoryType {
  func create(_ todo: TodoMate.TodoDTO) throws -> TodoDTO {
    .stub
  }

  func readAll() async throws -> [TodoDTO] {
    TodoDTO.stubs
  }

  func update(_ todo: TodoDTO) throws { // 추가
    guard let handler = updateHandler else {
      throw NSError(domain: "Mock", code: -1, userInfo: nil)
    }
    try handler(todo)
  }

  func delete(id: String) {}

  // Behavior를 통해 각 메서드의 동작을 테스트마다 자유롭게 정의
  var createTodoHandler: ((TodoDTO) async throws -> TodoDTO)?
  var updateHandler: ((TodoDTO) throws -> Void)?
  var fetchTodosByUserHandler: ((String, Date, Date) async throws -> [TodoDTO])?
  var fetchTodosByGroupHandler: ((String, Date, Date) async throws -> [TodoDTO])?
  var updateTodoHandler: ((TodoDTO) async throws -> Void)?
  var deleteTodoHandler: ((String) async throws -> Void)?

  func createTodo(_ todoDTO: TodoDTO) async throws -> TodoDTO {
    guard let handler = createTodoHandler else { throw NSError(
      domain: "Test",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "createTodoHandler not set"]
    ) }
    return try await handler(todoDTO)
  }

  func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
    guard let handler = fetchTodosByUserHandler else { return [] }
    return try await handler(userId, startDate, endDate)
  }

  func fetchTodos(groupId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
    guard let handler = fetchTodosByGroupHandler else { return [] }
    return try await handler(groupId, startDate, endDate)
  }

  func updateTodo(todo: TodoDTO) async throws {
    guard let handler = updateTodoHandler else { return }
    try await handler(todo)
  }

  func deleteTodo(todoId: String) async throws {
    guard let handler = deleteTodoHandler else { return }
    try await handler(todoId)
  }
}
