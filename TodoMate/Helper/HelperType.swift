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
    func create(_ todo: Todo)
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(userId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

protocol ImageUploadServiceType {
    func upload(data: Data) async -> String
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
    func create(with url: String?)
}
