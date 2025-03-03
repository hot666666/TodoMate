//
//  UserInfoService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

class TodoOrderService: TodoOrderServiceType {
    private let userDefaults = UserDefaults.standard
    private let todoOrderDateKey = Const.TodoOrderDateKey
    private let todoOrderKey = Const.TodoOrderKey
    
    func saveDate(_ date: Date) {
        userDefaults.set(date, forKey: todoOrderDateKey)
    }
    
    func loadDate() -> Date? {
        userDefaults.object(forKey: todoOrderDateKey) as? Date
    }
    
    func saveOrder(_ order: [String]) {
        userDefaults.set(order, forKey: todoOrderKey)
    }
    
    func loadOrder() -> [String] {
        userDefaults.array(forKey: todoOrderKey) as? [String] ?? []
    }
}


