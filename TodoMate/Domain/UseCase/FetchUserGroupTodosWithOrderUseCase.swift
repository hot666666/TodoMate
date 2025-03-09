//
//  FetchUserGroupTodosWithOrderUseCase.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import Foundation

enum FetchUserGrouptodosWithOrderUseCaseError: Error {
    case userNotFoundInTodos
}

protocol FetchUserGroupTodosWithOrderUseCaseType {
    func execute(for userInfo: AuthenticatedUser) async throws -> [String: [Todo]]
}

final class FetchUserGroupTodosWithOrderUseCase: FetchUserGroupTodosWithOrderUseCaseType {
    private let todoService: TodoServiceType
    private let todoOrderService: TodoOrderServiceType
    
    init(todoService: TodoServiceType, todoOrderService: TodoOrderServiceType) {
        self.todoService = todoService
        self.todoOrderService = todoOrderService
    }
    
    func execute(for userInfo: AuthenticatedUser) async throws -> [String: [Todo]] {
        let today = Date.now
        
        let userGroupTodoList = await todoService.fetchToday(groupId: userInfo.gid)
        var todosByUid = makeTodosByUidDict(userGroupTodoList)
        
        guard let userTodos = todosByUid[userInfo.uid] else {
            throw FetchUserGrouptodosWithOrderUseCaseError.userNotFoundInTodos
        }
        
        // TODO: - Clear all orders before today
        /// todoService.clearOrders(before: today)
        if let existingOrder = todoOrderService.loadOrder(for: today) {
            let orderedUserTodos = applyOrder(userTodos, order: existingOrder)
            todosByUid[userInfo.uid] = orderedUserTodos
        } else {
            let newOrder = makeOrder(from: userTodos)
            todoOrderService.saveOrder(newOrder, for: today)
        }
        
        return todosByUid
    }
    
    private func makeTodosByUidDict(_ todos: [Todo]) -> [String: [Todo]] {
        todos.reduce(into: [String: [Todo]]()) { result, todo in
            result[todo.uid, default: []].append(todo)
        }
    }
    
    private func makeOrder(from todos: [Todo]) -> [String] {
        todos.map { $0.fid }
    }
    
    private func applyOrder(_ todos: [Todo], order: [String]) -> [Todo] {
        var todos = todos
        todos.sort { order.firstIndex(of: $0.fid) ?? Int.max < order.firstIndex(of: $1.fid) ?? Int.max }
        return todos
    }
}

class StubFetchUserGroupTodosWithOrderUseCase: FetchUserGroupTodosWithOrderUseCaseType {
    func execute(for userInfo: AuthenticatedUser) async throws -> [String : [Todo]] {
        let todos = Todo.stub
        return ["uid": todos]
    }
}
