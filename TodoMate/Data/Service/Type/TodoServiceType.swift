//
//  StubTodoService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

protocol TodoServiceType {
    func create(from todo: Todo) async -> Todo?
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(groupId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

class StubTodoService: TodoServiceType {
    private let calendar = Calendar.current
    
    func create(from todo: Todo) async -> Todo? {
        var _todo = todo
        _todo.fid = UUID().uuidString
        return _todo
    }
    
    func create(_ todo: Todo) {
        
    }
    
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date : [Todo]] {
        let todos = Todo.stub.filter { $0.uid == userId && startDate...endDate ~= $0.date }
        return todos.reduce(into: [:]) { todosGroupByDate, todo in
            todosGroupByDate[calendar.startOfDay(for: todo.date), default: []].append(todo)
        }
    }
    
    func fetchToday(groupId: String) async -> [Todo] {
        Todo.stub.filter { calendar.isDateInToday($0.date) }
    }
    
    func update(_ todo: Todo) {
        
    }
    
    func remove(_ todo: Todo) {
        
    }
}
