//
//  StubHelper.swift
//  TodoMate
//
//  Created by hs on 8/20/24.
//

import Foundation

// Stateless
class StubTodoService: TodoServiceType {
    private let calendar = Calendar.current
    
    func create(_ todo: Todo) {
        
    }
    
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date : [Todo]] {
        let todos = Todo.stub
        return todos.reduce(into: [:]) { todosGroupByDate, todo in
            todosGroupByDate[calendar.startOfDay(for: todo.date), default: []].append(todo)
        }
    }
    
    func fetchToday(userId: String) async -> [Todo] {
        Todo.stub.filter { calendar.isDateInToday($0.date) }
    }
    
    func update(_ todo: Todo) {
        
    }
    
    func remove(_ todo: Todo) {
        
    }
}

class StubTodoRealtimeService: TodoRealtimeServiceType {
    func addObserver(_ observer: TodoObserver, for userId: String) {
        
    }
    
    func removeObserver(_ observer: TodoObserver,for userId: String) {
        
    }
}

class StubImageUploadService: ImageUploadServiceType {
    func upload(data: Data) async -> String {
        ""
    }
}

class StubChatService: ChatServiceType {
    func fetch() async -> [Chat] {
        Chat.stub
    }
    
    var chats: [Chat] = []
    
    var formatCount: String {
        chats.count > 0 ? "(\(chats.count))" : ""
    }
    
    func remove(_ chat: Chat) {

    }
    
    func update(_ chat: Chat) {

    }
    
    func create(with url: String?) {

    }
    
    func observeChatChanges() -> AsyncStream<DatabaseChange<Chat>> {
        AsyncStream { continuation in
            Task {
                for chat in Chat.stub {
                    continuation.yield(.added(chat))
                }
                continuation.finish()
            }
        }
    }
    
    func cancelTask() {
        
    }
}

// Statefull
@Observable
class StubUserManager: UserManagerType {
    var users: [User] = []
    
    @MainActor
    func fetch() async {
        users = User.stub
    }
    
    func update(_ user: User) {
        
    }
}
