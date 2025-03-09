//
//  ManageWidgetDataUseCase.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

protocol SyncWidgetDataWithUserTodoUseCaseType {
    func sync(for currentTodo: Todo, updatedTodo: Todo) async
}

final class SyncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType {
    private let widgetDataManager: WidgetDataManagerType
    
    init(widgetDataManager: WidgetDataManagerType) {
        self.widgetDataManager = widgetDataManager
    }
    
    func sync(for currentTodo: Todo, updatedTodo: Todo) async {
        let widgetTodo = updatedTodo.toWidgetTodo()
        let wasInProgress = currentTodo.status == .inProgress
        let isInProgress = updatedTodo.status == .inProgress
        
        if !wasInProgress && isInProgress {
            await widgetDataManager.save(widgetTodo)
        } else if wasInProgress && !isInProgress {
            await widgetDataManager.remove(widgetTodo.fid)
        }
    }
}

final class StubSyncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType {
    func sync(for currentTodo: Todo, updatedTodo: Todo) async {
        print("[StubManageWidgetDataUseCase] - manageWidgetData")
    }
}

