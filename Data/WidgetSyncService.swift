//
//  WidgetSyncService.swift
//  Todo
//
//  Created by Claude on 6/27/25.
//

import SwiftData
import WidgetKit

final class SwiftDataWidgetSyncService: WidgetSyncService {
  private let todoRepository: TodoRepository
  private let authService: AuthService
  private let modelContext: ModelContext

  init(
    todoRepository: TodoRepository,
    authService: AuthService,
    modelContext: ModelContext
  ) {
    self.todoRepository = todoRepository
    self.authService = authService
    self.modelContext = modelContext
  }

  @MainActor
  func sync() async {
    do {
      // 1. 현재 로그인된 사용자 ID 확인
      guard let userId = authService.signedInUserId else {
        await clearAllWidgetTodos()
        return
      }

      // 2. 유저의 진행중인 Todo들만 패치 (캐시 사용)
      let query = TodoQuery()
        .owner(userId: userId)
        .status(.inProgress)
      let inProgressTodos = try await todoRepository.readAll(query: query, source: .cache)

      // 3. SwiftData 업데이트
      await replaceAllWidgetTodos(with: inProgressTodos)

      // 4. 위젯 갱신
      WidgetCenter.shared.reloadAllTimelines()

      print("[WidgetSyncUseCase] - Synced \(inProgressTodos.count) in-progress todos for user: \(userId)")

    } catch {
      print("[WidgetSyncUseCase] - Failed to sync widget todos: \(error)")
    }
  }

  // MARK: - Private Methods

  @MainActor
  private func replaceAllWidgetTodos(with todos: [Todo]) async {
    do {
      // 1. 기존 데이터 전체 삭제 (효율적)
      try modelContext.delete(model: WidgetTodo.self)

      // 2. 새 데이터 삽입
      for todo in todos {
        let widgetTodo = WidgetTodo.from(todo)
        modelContext.insert(widgetTodo)
      }

      // 3. 한 번에 저장
      try modelContext.save()

    } catch {
      print("[WidgetSyncUseCase] - Failed to replace widget todos: \(error)")
    }
  }

  @MainActor
  private func clearAllWidgetTodos() async {
    do {
      try modelContext.delete(model: WidgetTodo.self)
      try modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()
      print("[WidgetSyncUseCase] - Cleared all widget todos (user logged out)")
    } catch {
      print("[WidgetSyncUseCase] - Failed to clear widget todos: \(error)")
    }
  }
}

// MARK: - Stub Implementation

final class StubWidgetSyncService: WidgetSyncService {
  func sync() async {
    print("[StubWidgetSyncUseCase] - Sync completed (stub)")
  }
}
