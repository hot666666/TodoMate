//
//  StubTodoService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

protocol TodoServiceType {
    func create(_ todo: Todo)
    func create(from todo: Todo) async -> Todo?
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(userId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

class StubTodoService: TodoServiceType {
    private let calendar = Calendar.current
    
    func create(from todo: Todo) async -> Todo? {
        todo.fid = UUID().uuidString
        return todo
    }
    
    func create(_ todo: Todo) {
        
    }
    
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date : [Todo]] {
        let todos = Todo.stub.filter { $0.uid == userId && startDate...endDate ~= $0.date }
        return todos.reduce(into: [:]) { todosGroupByDate, todo in
            todosGroupByDate[calendar.startOfDay(for: todo.date), default: []].append(todo)
        }
    }
    
    func fetchToday(userId: String) async -> [Todo] {
        Todo.stub.filter { calendar.isDateInToday($0.date) && $0.uid == userId }
    }
    
    func update(_ todo: Todo) {
        
    }
    
    func remove(_ todo: Todo) {
        
    }
}
