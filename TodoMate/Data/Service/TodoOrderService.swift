//
//  TodoOrderService.swift
//  TodoMate
//
//  Created by hs on 3/5/25.
//

import Foundation

class TodoOrderService: TodoOrderServiceType {
    private let todoOrderRepository: TodoOrderRepositoryType
    private let calendar = Calendar.current
    
    init(todoOrderRepository: TodoOrderRepositoryType = TodoOrderRepository()) {
        self.todoOrderRepository = todoOrderRepository
    }
    
    func saveOrder(_ order: [String], for date: Date) {
        todoOrderRepository.saveOrder(order)
        todoOrderRepository.saveDate(date)
    }
    
    func loadOrder(for date: Date) -> [String]? {
        guard let lastSavedDate = todoOrderRepository.loadDate(),
              calendar.isDate(date, inSameDayAs: lastSavedDate) else {
            return nil
        }
        return todoOrderRepository.loadOrder()
    }
}
