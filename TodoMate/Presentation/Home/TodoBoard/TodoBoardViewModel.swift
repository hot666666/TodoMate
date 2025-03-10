//
//  TodoBoardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI
import Foundation

@Observable
class TodoBoardViewModel {
    private let calendar = Calendar.current
    private let todoStreamProvider: TodoStreamProviderType
    private let widgetDataManager: WidgetDataManagerType
    private let todoService: TodoServiceType
    private let todoOrderService: TodoOrderServiceType
    
    private let fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType
    private let saveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType
    private let syncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType
    
    @ObservationIgnored let userInfo: AuthenticatedUser
    
    /// '오늘' 할 일
    var todosByUser: [String: [Todo]] = [:]
    
    init(container: DIContainer, userInfo: AuthenticatedUser) {
        self.todoStreamProvider = container.todoStreamProvider
        
        self.widgetDataManager = container.widgetDataManager
        self.todoService = container.todoService
        self.todoOrderService = container.todoOrderService
        
        self.fetchTodosByUserUseCase = container.fetchTodosByUserUseCase
        self.saveUserTodosOrderUseCase = container.saveUserTodosOrderUseCase
        self.syncWidgetDataWithUserTodoUseCase = container.syncWidgetDataWithUserTodoUseCase
        
        self.userInfo = userInfo
    }
    
    // MARK: - 상태 관리 메서드
    
    func setAllTodoStates(with allTodos: [String: [Todo]]) {
        todosByUser = allTodos
    }
    
    func setUserTodoStates(with userTodos: [Todo]) {
        todosByUser[userInfo.uid, default: []] = userTodos
    }
    
    func addTodoState(with todo: Todo) {
        guard !isTodoAlreadyAdded(todo) else { return }
        todosByUser[todo.uid, default: []].append(todo)
    }
    
    func updateTodoState(with todo: Todo) {
        guard
            var todos = todosByUser[todo.uid],
            let index = todos.firstIndex(where: { $0.fid == todo.fid }),
            todos[index] != todo
        else { return }
        todos[index] = todo
        todosByUser[todo.uid] = todos
    }
    
    func removeTodoState(for todo: Todo) {
        todosByUser[todo.uid, default: []].removeAll(where: { $0.fid == todo.fid })
    }
}

extension TodoBoardViewModel {
    func observeChanges() async {
        for await change in todoStreamProvider.createTodoStream() {
            await handleTodoChange(change)
        
            guard isMine(change.data), isToday(change.data.date) else { continue }
            saveUserTodosOrderUseCase.execute(with: myTodoList ?? [], for: .now)
        }
    }
    
    @MainActor
    func fetchTodos() async {
        if let todosByUser = try? await fetchTodosByUserUseCase.execute(for: userInfo){
            setAllTodoStates(with: todosByUser)
        }
    }
    
    @MainActor
    func createTodo() async {
        guard let createdTodo = await todoService.create(from: Todo(uid: userInfo.uid)) else { return }
        
        addTodoState(with: createdTodo)
    }
    
    func updateTodo(from currentTodo: Todo, to updatedTodo: Todo) {
        guard isMine(currentTodo), isValidUpdate(from: currentTodo, to: updatedTodo) else { return }
        
        todoService.update(updatedTodo)
            
        updateTodoState(with: updatedTodo)
        
        // 내가 현재 앱에서 status를 변경하는 경우에만 위젯 업데이트
        Task {
            await syncWidgetDataWithUserTodoUseCase.sync(for: currentTodo, updatedTodo: updatedTodo)
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        guard isMine(todo) else { return }
        
        todoService.remove(todo)
        
        removeTodoState(for: todo)
    }
    
    func moveTodo(from source: IndexSet, to destination: Int) {
        guard var myTodoList = myTodoList else { return }
        myTodoList.move(fromOffsets: source, toOffset: destination)
        
        saveUserTodosOrderUseCase.execute(with: myTodoList, for: .now)
        
        setUserTodoStates(with: myTodoList)
    }
    
    func todosBinding(for user: User) -> Binding<[Todo]> {
        Binding(
            get: { self.todosByUser[user.uid] ?? [] },
            set: { self.todosByUser[user.uid] = $0 }
        )
    }
    
    func isMe(_ user: User) -> Bool {
        user.uid == userInfo.uid
    }
}

extension TodoBoardViewModel {
    func handleTodoChange(_ change: DatabaseChange<Todo>) async {
        switch change {
        case .added(let todo):
            await handleAddedTodo(todo)
        case .modified(let todo):
            await handleModifiedTodo(todo)
        case .removed(let todo):
            await handleRemovedTodo(todo)
        }
    }
    
    @MainActor
    private func handleAddedTodo(_ todo: Todo) async {
        guard isToday(todo.date) && !isTodoAlreadyAdded(todo) else { return }
        
        addTodoState(with: todo)
    }
    
    @MainActor
    private func handleModifiedTodo(_ todo: Todo) async {
        let isTodayTodo = isToday(todo.date)
        let isAlreadyAdded = isTodoAlreadyAdded(todo)
        
        if isAlreadyAdded {
            if isTodayTodo {
                updateTodoState(with: todo)
            } else {
                removeTodoState(for: todo)
            }
        } else if isTodayTodo {
            addTodoState(with: todo)
        }
    }
    
    @MainActor
    private func handleRemovedTodo(_ todo: Todo) async {
        guard isToday(todo.date) else { return }
        
        removeTodoState(for: todo)
    }
}
 
extension TodoBoardViewModel {
    private func isMine(_ todo: Todo) -> Bool {
        todo.uid == userInfo.uid
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isTodoAlreadyAdded(_ todo: Todo) -> Bool {
        todosByUser[todo.uid]?.contains { $0.fid == todo.fid } ?? false
    }
    
    private var myTodoList: [Todo]? {
        todosByUser[userInfo.uid]
    }
    
    private func isValidUpdate(from currentTodo: Todo, to updatedTodo: Todo) -> Bool {
        if currentTodo.status == .inProgress {
            return updatedTodo.status != .inProgress
        }
        return true
    }
}
