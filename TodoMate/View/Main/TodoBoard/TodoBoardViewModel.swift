//
//  TodoBoardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI
import SwiftData

@Observable
class TodoBoardViewModel {
    private let todoStreamProvider: TodoStreamProviderType
    private let userService: UserServiceType
    private let modelContainer: ModelContainer
    private var observers: [String: [WeakTodoObserver]] = [:]
    
    @ObservationIgnored let userInfo: UserInfo
    var users: [User] = []
    
    init(container: DIContainer, userInfo: UserInfo) {
        self.todoStreamProvider = container.todoStreamProvider
        self.userService = container.userService
        self.modelContainer = container.modelContainer
        self.userInfo = userInfo
    }
    
    func isMe(_ user: User) -> Bool {
        user.uid == userInfo.id
    }
}
extension TodoBoardViewModel {
    @MainActor
    func fetchGroupUser() async {
        users = await userService.fetch()
    }
}
extension TodoBoardViewModel {
    func observeChanges() async {
        for await change in todoStreamProvider.createTodoStream() {
            if !observers.isEmpty {
                print("[Observed Todo change in FirebaseFirestore] - ", change)
                await handleDatabaseChange(change)
            }
        }
        
        print("[Stopped observing Todo changes]")
        observers.removeAll()
    }
    
    @MainActor
    private func handleDatabaseChange(_ change: DatabaseChange<Todo>) async {
        guard let observers = observers[change.data.uid] else {
            print("[No Observer exists]")
            return
        }
        
        switch change {
        case .added(let todo):
            for observer in observers {
                observer.value?.todoAdded(todo)
            }
        case .modified(let todo):
            /// 위젯 데이터 - 본인 것만 진행 중이면 추가, 아니면 삭제, 이미 존재하는 Todo의 업데이트라면 무시
            guard todo.uid == userInfo.id else { break }
            
            if todo.status == .inProgress {
                await saveToModelContainer(todo)
            } else {
                await deleteFromModelContainer(todo.fid)
            }
            
            for observer in observers {
                observer.value?.todoModified(todo)
            }
        case .removed(let todo):
            /// 위젯 데이터 - 존재하면 삭제
            guard todo.uid == userInfo.id else { break }

            await deleteFromModelContainer(todo.fid)
            
            for observer in observers {
                observer.value?.todoRemoved(todo)
            }
        }
    }
}
extension TodoBoardViewModel {
    @MainActor
    private func saveToModelContainer(_ todo: Todo) async {
        let entity = todo.toEntity()
        guard let fid = entity.fid else {
            print("TodoEntity has no fid")
            return
        }
        
        let context = modelContainer.mainContext
        
        let fetchDescriptor = FetchDescriptor<TodoEntity>(predicate: #Predicate { $0.fid == fid })
        do {
            if let existingEntity = try context.fetch(fetchDescriptor).first {
                existingEntity.date = entity.date
                existingEntity.content = entity.content
                return
            }
            context.insert(entity)
            print("New TodoEntity inserted with fid \(fid)")
        } catch {
            print("Error checking for existing TodoEntity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func deleteFromModelContainer(_ todoFid: String?) async {
        guard let todoFid else { return }
        
        let context = modelContainer.mainContext
        
        let fetchDescriptor = FetchDescriptor<TodoEntity>(predicate: #Predicate { $0.fid == todoFid })
        if let existingEntity = try? context.fetch(fetchDescriptor).first {
            context.delete(existingEntity)
            print("TodoEntity deleted")
        }
    }
}
extension TodoBoardViewModel {
    func addObserver(_ observer: TodoObserverType, for userId: String) {
        observers[userId, default: []].removeAll(where: { $0.value == nil })
        print("[Add Observer - \(ObjectIdentifier(observer))]")
        observers[userId, default: []].append(WeakTodoObserver(observer))
    }
    
    func removeObserver(_ observer: TodoObserverType, for userId: String) {
        if observers[userId, default: []].contains(where: { $0.value === observer }) {
            print("[Remove Observer - \(ObjectIdentifier(observer))]")
        }
        observers[userId, default: []].removeAll(where: { $0.value === observer || $0.value == nil })
    }
}
