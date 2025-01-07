//
//  ServiceType.swift
//  TodoMate
//
//  Created by hs on 1/7/25.
//

import Foundation

protocol UserServiceType {
    func fetch() async -> [User]
    func update(_ user: User)
}

protocol TodoServiceType {
    func create(_ todo: Todo)
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]]
    func fetchToday(userId: String) async -> [Todo]
    func update(_ todo: Todo)
    func remove(_ todo: Todo)
}

protocol TodoObserver: AnyObject {
    func todoAdded(_ todo: Todo)
    func todoModified(_ todo: Todo)
    func todoRemoved(_ todo: Todo)
}

protocol TodoRealtimeServiceType {
    func addObserver(_ observer: TodoObserver, for userId: String)
    func removeObserver(_ observer: TodoObserver, for userId: String)
}

protocol ImageUploadServiceType {
    func upload(data: Data) async -> String  /// URL
}

protocol ChatServiceType {
    func fetch() async -> [Chat]
    func remove(_ chat: Chat)
    func update(_ chat: Chat)
    func create(with url: String?)
    func observeChatChanges() -> AsyncStream<DatabaseChange<Chat>>
    func cancelTask()
}
