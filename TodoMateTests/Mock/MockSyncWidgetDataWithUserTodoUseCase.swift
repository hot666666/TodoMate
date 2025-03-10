//
//  MockSyncWidgetDataWithUserTodoUseCase.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

@testable import TodoMate

final class MockSyncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType {
    func sync(for currentTodo: Todo, updatedTodo: Todo) async {
        // no-op
    }
}
