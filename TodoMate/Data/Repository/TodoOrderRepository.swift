//
//  UserInfoService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

class TodoOrderRepository: TodoOrderRepositoryType {
    private let userDefaults: UserDefaults
    /// PREVIEW용 키 따로 존재
    private let todoOrderDateKey = Const.TodoOrderDateKey
    private let todoOrderKey = Const.TodoOrderKey
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
#if DEBUG || PREVIEW
        userDefaults.removePersistentDomain(forName: "TestUserDefaults")
#endif
    }
    
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
