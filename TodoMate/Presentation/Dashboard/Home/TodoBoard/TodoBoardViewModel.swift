//
//  TodoBoardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI
import Foundation

// TODO: - ViewStatus
@Observable
class TodoBoardViewModel {
    private let calendar = Calendar.current
    private let todoStreamProvider: TodoStreamProviderType
    private let widgetDataManager: WidgetDataManager
    private let todoService: TodoServiceType
    
    @ObservationIgnored let userInfo: AuthenticatedUser
    
    /// '오늘' 할 일
    var todosByUser: [String: [Todo]] = [:]
    
    init(container: DIContainer, userInfo: AuthenticatedUser) {
        self.todoStreamProvider = container.todoStreamProvider
        self.widgetDataManager = container.widgetDataManager
        self.todoService = container.todoService
        
        self.userInfo = userInfo
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
    
    func isMine(_ todo: Todo) -> Bool {
        todo.uid == userInfo.uid
    }
}
extension TodoBoardViewModel {
    func observeChanges() async {
        for await change in todoStreamProvider.createTodoStream() {
            await handleDatabaseChange(change)
        }
    }
    
    @MainActor
    func fetchTodos() async {
        todosByUser = await getTodosByUser()
    }
    
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
        }
    }
}
