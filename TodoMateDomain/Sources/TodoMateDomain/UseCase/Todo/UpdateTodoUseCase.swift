//
//  UpdateTodoUseCase.swift
//  TodoMate
//
//
//  Created by hs on 6/30/25.
//

import Common
import Foundation

public protocol UpdateTodoUseCase {
  func run(for userId: String, _ todo: Todo) async throws
}

public final class UpdateTodoUseCaseImpl: UpdateTodoUseCase {
  private let repository: TodoRepository

  public init(repository: TodoRepository) {
    self.repository = repository
  }

  public func run(for userId: String, _ todo: Todo) async throws {
    guard todo.owner == userId else { throw TodoUseCaseError.userNotAuthorized }
    try await repository.update(todo)
  }
}

public final class StubUpdateTodoUseCase: UpdateTodoUseCase {
  public init() {}
  public func run(for _: String, _: Todo) async throws {}
}

public protocol SyncTodayTodosUseCase {
  func run(for userId: String, in date: Date) async throws
}

public final class SyncTodayTodosUseCaseImpl: SyncTodayTodosUseCase {
  private let localRepository: TodoRepository
  private let remoteRepository: TodoRepository

  public init(localRepository: TodoRepository, remoteRepository: TodoRepository) {
    self.localRepository = localRepository
    self.remoteRepository = remoteRepository
  }

  public func run(for userId: String, in date: Date) async throws {
    // 1. Fetch todos from both repositories
    let query = TodoQuery()
      .owner(userId: userId)
      .dateRange(date.dayRange)

    let localRepo = localRepository
    let remoteRepo = remoteRepository

    async let localTodos = try localRepo.readAll(query: query, source: .cache)
    async let remoteTodos = try remoteRepo.readAll(query: query, source: .server)

    let (local, remote) = try await (localTodos, remoteTodos)

    // 2. Sync Local -> Remote
    for localTodo in local where !localTodo.isDeleted {
      if let remoteTodo = remote.first(where: { $0.id == localTodo.id }) {
        // Conflict resolution: Last write wins
        if localTodo.updatedAt > remoteTodo.updatedAt {
          try await remoteRepository.update(localTodo)
        }
      } else {
        // Create in remote if missing (ensure owner is set)
        var newRemoteTodo = localTodo
        if newRemoteTodo.owner.isEmpty {
          newRemoteTodo = Todo(
            id: localTodo.id,
            content: localTodo.content,
            status: localTodo.status,
            detail: localTodo.detail,
            date: localTodo.date,
            createdAt: localTodo.createdAt,
            updatedAt: localTodo.updatedAt,
            owner: userId,
            isDeleted: localTodo.isDeleted,
          )
        }
        try await remoteRepository.create(newRemoteTodo)
      }
    }

    // 3. Sync Remote -> Local
    for remoteTodo in remote where !remoteTodo.isDeleted {
      if let localTodo = local.first(where: { $0.id == remoteTodo.id }) {
        // Conflict resolution: Last write wins
        if remoteTodo.updatedAt > localTodo.updatedAt {
          try await localRepository.update(remoteTodo)
        }
      } else {
        // Create in local if missing
        try await localRepository.create(remoteTodo)
      }
    }
  }
}
