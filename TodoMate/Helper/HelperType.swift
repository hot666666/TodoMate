//
//  HelperType.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Foundation

protocol TodoObserver: AnyObject {
    func todoAdded(_ todo: Todo)
    func todoModified(_ todo: Todo)
    func todoRemoved(_ todo: Todo)
}

// Stateless
protocol TodoRealtimeServiceType {
    func addObserver(_ observer: TodoObserver, for userId: String)
    func removeObserver(_ observer: TodoObserver, for userId: String)
}

protocol TodoServiceType {
    func create(with uid: String, date: Date)
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(userId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

// Stateful
protocol UserManagerType {
    var users: [User] { get }
    func fetch() async
    func update(_ user: User)
    // TODO: - 추가기능
    ///    func create(_ user: Todo) async
    ///    func remove(_ todo: Todo)
}

protocol ChatManagerType {
    var chats: [Chat] { get set }
    var formatCount: String { get }
    func fetch() async
    func remove(_ chat: Chat)
    func update(_ chat: Chat)
    func create(_ chat: Chat)
}
