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
    
    @ObservationIgnored let userInfo: AuthenticatedUser
    
    /// '오늘' 할 일
    var todosByUser: [String: [Todo]] = [:]
    
    init(container: DIContainer, userInfo: AuthenticatedUser) {
        self.todoStreamProvider = container.todoStreamProvider
        self.widgetDataManager = container.widgetDataManager
        self.todoService = container.todoService
        self.todoOrderService = container.todoOrderService
        
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
            switch change {
                case .added(let todo):
                    await handleAddedTodo(todo)
                case .modified(let todo):
                    await handleModifiedTodo(todo)
                case .removed(let todo):
                    await handleRemovedTodo(todo)
            }
        }
    }
    
    @MainActor
    func fetchTodos() async {
        var todosByUser = await getTodosByUser()
        var todoList = todosByUser[userInfo.uid, default: []]
        
        let today: Date = .now
        if let orderedFids = todoOrderService.loadOrder(for: today) {
            // 저장된 순서가 오늘 날짜와 일치하면 해당 순서 적용
            todoList.sort { orderedFids.firstIndex(of: $0.fid) ?? Int.max < orderedFids.firstIndex(of: $1.fid) ?? Int.max }
            todosByUser[userInfo.uid] = todoList
        } else {
            // 저장된 순서가 없거나 날짜가 다르면 새로 저장
            todoOrderService.saveOrder(todoList.map { $0.fid }, for: today)
        }
        
        setAllTodoStates(with: todosByUser)
    }
    
    @MainActor
    func createTodo() async {
        guard let createdTodo = await todoService.create(from: Todo(uid: userInfo.uid)) else { return }
        
        addTodoState(with: createdTodo)
    }
    
    func updateTodo(_ todo: Todo) {
        guard isMine(todo) else { return }
        
        todoService.update(todo)
        
        updateTodoState(with: todo)
    }
    
    func deleteTodo(_ todo: Todo) {
        guard isMine(todo) else { return }
        
        todoService.remove(todo)
        
        removeTodoState(for: todo)
    }
    
    func moveTodo(from source: IndexSet, to destination: Int) {
        // TODO: - isMine인 요소에 대해서만 수행하지만 다른 방식으로 이를 수행하도록 수정하면 좋을 듯
        guard var todoList = todosByUser[userInfo.uid] else { return }
        /// 특히 다른 배열로 수행된다면 다음코드는 크래시발생할 수 있음
        todoList.move(fromOffsets: source, toOffset: destination)
        
        setUserTodoStates(with: todoList)
        
//        saveFidOrder()
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
    @MainActor
    func handleAddedTodo(_ todo: Todo) async {
        guard isToday(todo.date) && !isTodoAlreadyAdded(todo) else { return }
        
        addTodoState(with: todo)
    }
    
    @MainActor
    func handleModifiedTodo(_ todo: Todo) async {
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
    func handleRemovedTodo(_ todo: Todo) async {
        guard isToday(todo.date) else { return }
        
        removeTodoState(for: todo)
    }
    
    private func getTodosByUser() async -> [String: [Todo]] {
        // TODO: - todos에 전부 group에 존재하는 uid라 가정
        var todosByUser = [String: [Todo]]()
        await todoService.fetchToday(groupId: userInfo.gid).forEach { todo in
            todosByUser[todo.uid, default: []].append(todo)
        }
        return todosByUser
    }
    
    private func isMine(_ todo: Todo) -> Bool {
        todo.uid == userInfo.uid
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isTodoAlreadyAdded(_ todo: Todo) -> Bool {
        todosByUser[todo.uid]?.contains { $0.fid == todo.fid } ?? false
    }
}
