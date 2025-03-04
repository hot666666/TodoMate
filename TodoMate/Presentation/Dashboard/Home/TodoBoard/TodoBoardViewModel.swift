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
    private let widgetDataManager: WidgetDataManager
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
}
extension TodoBoardViewModel {
    func todosBinding(for user: User) -> Binding<[Todo]> {
        Binding(
            get: { self.todosByUser[user.uid] ?? [] },
            set: { self.todosByUser[user.uid] = $0 }
        )
    }
    
    func isMe(_ user: User) -> Bool {
        user.uid == userInfo.uid
    }
    
    func observeChanges() async {
        for await change in todoStreamProvider.createTodoStream() {
            await handleDatabaseChange(change)
        }
    }
    
    @MainActor
    func fetchTodos() async {
        var todosByUser = await getTodosByUser()
        var todoList = todosByUser[userInfo.uid] ?? []
        
        let today: Date = .now
        /// 마지막 저장 날짜가 없는 경우
        guard let lastSavedDate = todoOrderService.loadDate() else {
            todoOrderService.saveOrder(todoList.map { $0.fid })
            todoOrderService.saveDate(today)
            return
        }
        
        /// 마지막 저장 날짜가 오늘인 경우
        if calendar.isDateInToday(lastSavedDate) {
            let orderedFids = todoOrderService.loadOrder()
            todoList.sort { orderedFids.firstIndex(of: $0.fid) ?? Int.max < orderedFids.firstIndex(of: $1.fid) ?? Int.max }
            todosByUser[userInfo.uid] = todoList
        /// 마지막 저장 날짜가 오늘이 아닌 경우
        } else {
            todoOrderService.saveOrder(todoList.map { $0.fid })
            todoOrderService.saveDate(today)
        }
        
        self.todosByUser = await getTodosByUser()
    }
}
extension TodoBoardViewModel {
    @MainActor
    func createTodo() async {
        if let createdTodo = await getCreatedTodo() {
            todosByUser[userInfo.uid, default: []].append(createdTodo)
        }
    }
    
    func updateTodo(_ todo: Todo) {
        guard isMine(todo) else { return }
        
        todoService.update(todo)
        
        if var todoList = todosByUser[userInfo.uid],
            let index = todoList.firstIndex(where: { $0.fid == todo.fid }) {
            todoList[index] = todo
            todosByUser[userInfo.uid, default: []] = todoList
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        guard isMine(todo) else { return }
        
        todoService.remove(todo)
        
        todosByUser[userInfo.uid]?.removeAll(where: { $0.fid == todo.fid })
        
    }
    
    func moveTodo(from source: IndexSet, to destination: Int) {
        // TODO: - isMine인 요소에 대해서만 수행하지만 다른 방식으로 이를 수행하도록 수정하면 좋을 듯
        guard var todoList = todosByUser[userInfo.uid] else { return }
        
        /// 특히 다른 배열로 수행된다면 다음코드는 크래시발생할 수 있음
        todoList.move(fromOffsets: source, toOffset: destination)
        
        todosByUser[userInfo.uid, default: []] = todoList
        
        saveFidOrder()
    }
}
extension TodoBoardViewModel {
    private func getCreatedTodo() async -> Todo? {
        let todo = Todo(uid: userInfo.uid)
        guard let createdTodo = await todoService.create(from: todo), !createdTodo.fid.isEmpty else {
            print("Failed to create todo")
            return nil
        }
        return createdTodo
    }
    
    private func getTodosByUser() async -> [String: [Todo]] {
        // TODO: - todos에 전부 group에 존재하는 uid라 가정
        var todosByUser = [String: [Todo]]()
        await todoService.fetchToday(groupId: userInfo.gid).forEach { todo in
            todosByUser[todo.uid, default: []].append(todo)
        }
        return todosByUser
    }
    
    @MainActor
    private func handleDatabaseChange(_ change: DatabaseChange<Todo>) async {
        switch change {
        case .added(let todo):
            guard calendar.isDateInToday(todo.date) else { return }
            
            if let _ = todosByUser[todo.uid]?.firstIndex(where: { $0.fid == todo.fid }) {
                return
            }
            todosByUser[todo.uid, default: []].append(todo)
            
            if isMine(todo) {
                saveFidOrder()
            }
            
        case .modified(let todo):
            /// 오늘 Todo에 추가되어있는 경우
            if let index = todosByUser[todo.uid]?.firstIndex(where: { $0.fid == todo.fid }) {
                /// 오늘 -> 오늘
                if calendar.isDateInToday(todo.date) {
                    if var todoList = todosByUser[todo.uid],
                        let index = todoList.firstIndex(where: { $0.fid == todo.fid }) {
                        todoList[index] = todo
                        todosByUser[todo.uid, default: []] = todoList
                    }
                /// 오늘 -> 다른날짜
                } else {
                    todosByUser[todo.uid]?.remove(at: index)
                }
            /// 오늘 Todo에 추가되어있지 않은 경우
            } else {
                /// 다른날짜 -> 오늘
                if calendar.isDateInToday(todo.date) {
                    todosByUser[todo.uid, default: []].append(todo)
                }
            }
            
        case .removed(let todo):
            guard calendar.isDateInToday(todo.date) else { return }
            
            todosByUser[todo.uid]?.removeAll(where: { $0.fid == todo.fid })
            
            if isMine(todo) {
                saveFidOrder()
            }
        }
    }
    
    private func saveFidOrder() {
        let todoList = todosByUser[userInfo.uid] ?? []
        todoOrderService.saveOrder(todoList.map { $0.fid })
    }
}
extension TodoBoardViewModel {
    private func isMine(_ todo: Todo) -> Bool {
        todo.uid == userInfo.uid
    }
}
