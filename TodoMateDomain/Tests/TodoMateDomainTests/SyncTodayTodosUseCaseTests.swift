//
//  SyncTodayTodosUseCaseTests.swift
//  TodoMateDomainTests
//
//  Created by agent on 1/8/26.
//

import Foundation
import Testing

@testable import TodoMateDomain

// MARK: - SyncTodayTodosUseCase Tests

@Suite("SyncTodayTodosUseCase Unit Tests")
struct SyncTodayTodosUseCaseTests {
  @Test("Local New -> Remote Create")
  func sync_createsRemoteWhenMissing() async throws {
    let localRepo = InMemoryTodoRepository()
    let remoteRepo = InMemoryTodoRepository()
    let useCase = SyncTodayTodosUseCaseImpl(
      localRepository: localRepo, remoteRepository: remoteRepo,
    )

    let userId = "user1"
    let today = Date()
    let newTodo = Todo(owner: userId, content: "New Local", in: today)
    await localRepo.setTodos([newTodo])

    try await useCase.run(for: userId, in: today)

    let remoteTodos = await remoteRepo.todos
    #expect(remoteTodos.count == 1)
    #expect(remoteTodos.first?.id == newTodo.id)
    let callCount = await remoteRepo.createCallCount
    #expect(callCount == 1)
  }

  @Test("Local Newer UpdatedAt -> Remote Update")
  func sync_updatesRemoteWhenLocalIsNewer() async throws {
    let localRepo = InMemoryTodoRepository()
    let remoteRepo = InMemoryTodoRepository()
    let useCase = SyncTodayTodosUseCaseImpl(
      localRepository: localRepo, remoteRepository: remoteRepo,
    )

    let userId = "user1"
    let today = Date()

    var remoteTodo = Todo(owner: userId, content: "Old Content", in: today)
    remoteTodo.updatedAt = Date().addingTimeInterval(-3600)
    await remoteRepo.setTodos([remoteTodo])

    var localTodo = remoteTodo
    localTodo.content = "New Content"
    localTodo.updatedAt = Date()
    await localRepo.setTodos([localTodo])

    try await useCase.run(for: userId, in: today)

    let remoteTodos = await remoteRepo.todos
    #expect(remoteTodos.count == 1)
    #expect(remoteTodos.first?.content == "New Content")
    let callCount = await remoteRepo.updateCallCount
    #expect(callCount == 1)

    #expect(remoteTodos.count(where: { $0.id == remoteTodo.id }) == 1)
  }

  @Test("Remote Newer -> No Update")
  func sync_doesNotUpdateRemoteWhenRemoteIsNewer() async throws {
    let localRepo = InMemoryTodoRepository()
    let remoteRepo = InMemoryTodoRepository()
    let useCase = SyncTodayTodosUseCaseImpl(
      localRepository: localRepo, remoteRepository: remoteRepo,
    )

    let userId = "user1"
    let today = Date()

    var remoteTodo = Todo(owner: userId, content: "Remote Content", in: today)
    remoteTodo.updatedAt = Date()
    await remoteRepo.setTodos([remoteTodo])

    var localTodo = remoteTodo
    localTodo.content = "Local Old Content"
    localTodo.updatedAt = Date().addingTimeInterval(-3600)
    await localRepo.setTodos([localTodo])

    try await useCase.run(for: userId, in: today)

    let remoteTodos = await remoteRepo.todos
    #expect(remoteTodos.first?.content == "Remote Content")
    let callCount = await remoteRepo.updateCallCount
    #expect(callCount == 0)
  }
}
