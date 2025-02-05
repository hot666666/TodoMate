//
//  StubTodoOrderService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

protocol TodoOrderServiceType {
    func saveDate(_ date: Date)
    func loadDate() -> Date?
    func saveOrder(_ order: [String])
    func loadOrder() -> [String]
}

class StubTodoOrderService: TodoOrderServiceType {
    private var date: Date?
    private var order: [String] = []
    
    func saveDate(_ date: Date) {
        self.date = date
    }
    func loadDate() -> Date? {
        date
    }
    func saveOrder(_ order: [String]) {
        self.order = order
    }
    func loadOrder() -> [String] {
        order
    }
}
