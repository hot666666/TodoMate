//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol TodoRepository {
  func create(_ todo: Todo) throws
  func update(_ todo: Todo) throws
  func delete(_ todoId: String) async throws
  func readAll(query: TodoQuery, source: DataSource) async throws -> [Todo]
}
