//
//  TodoOrderService.swift
//  TodoMate
//
//  Created by hs on 3/5/25.
//

import Foundation

class TodoOrderService: TodoOrderServiceType {
    private let todoRepository: TodoOrderRepositoryType
    private let calendar = Calendar.current
    
    init(todoRepository: TodoOrderRepositoryType = TodoOrderRepository()) {
        self.todoRepository = todoRepository
    }
    
    func saveOrder(_ order: [String], for date: Date) {
        todoRepository.saveOrder(order)
        todoRepository.saveDate(date)
    }
    
    func loadOrder(for date: Date) -> [String]? {
        guard let lastSavedDate = todoRepository.loadDate(),
              calendar.isDate(date, inSameDayAs: lastSavedDate) else {
            return nil
        }
        return todoRepository.loadOrder()
    }
}
