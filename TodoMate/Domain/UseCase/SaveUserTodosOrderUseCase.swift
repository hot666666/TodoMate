//
//  SaveUserTodosOrderUseCase.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import Foundation

protocol SaveUserTodosOrderUseCaseType {
    func execute(with todos: [Todo], for date: Date)
}

final class SaveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType {
    private let calendar = Calendar.current
    private let todoOrderService: TodoOrderServiceType
    
    init(todoOrderService: TodoOrderServiceType) {
        self.todoOrderService = todoOrderService
    }
    
    func execute(with todos: [Todo], for date: Date = .now) {
        let today = calendar.startOfDay(for: date)
        let orders = todos.map { $0.fid }
        todoOrderService.saveOrder(orders, for: today)
    }
}
