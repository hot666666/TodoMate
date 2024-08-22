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
    
    func create(with uid: String) {
        
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

// Statefull
class StubUserManager: UserManagerType {
    var users: [User] = []
    
    func fetch() async {
        users = User.stub
    }
    
    func update(_ user: User) {
        
    }
}

class StubChatManager: ChatManagerType {
    var chats: [Chat] = []
    
    var formatCount: String {
        chats.count > 0 ? "(\(chats.count))" : ""
    }
    
    func fetch() async -> [Chat] {
        chats = Chat.stub
        return chats
    }
    
    func remove(_ chat: Chat) {

    }
    
    func update(_ chat: Chat) {

    }
    
    func create(_ chat: Chat) {

    }
}
