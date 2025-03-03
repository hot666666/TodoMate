//
//  TodoBoardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI

@Observable
class TodoBoardViewModel {
    private let todoStreamProvider: TodoStreamProviderType
    private let localDataManager: WidgetDataManager
    private var observers: [String: [WeakTodoObserver]] = [:]
    
    @ObservationIgnored let userInfo: AuthenticatedUser
    
    init(container: DIContainer, userInfo: AuthenticatedUser) {
        self.todoStreamProvider = container.todoStreamProvider
        self.localDataManager = container.localDataManager
        self.userInfo = userInfo
    }
    
    func isMe(_ user: User) -> Bool {
        user.uid == userInfo.uid
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
            /// 위젯 데이터 - 본인 것만 진행 중이면 추가, 아니면 삭제
            if todo.uid == userInfo.uid {
                if todo.status == .inProgress {
                    await localDataManager.save(todo.toEntity())
                } else {
                    await localDataManager.remove(todo.fid)
                }
            }
            
            for observer in observers {
                observer.value?.todoModified(todo)
            }
        case .removed(let todo):
            /// 위젯 데이터 - 존재하면 삭제
            guard todo.uid == userInfo.uid else { break }

            await localDataManager.remove(todo.fid)
            
            for observer in observers {
                observer.value?.todoRemoved(todo)
            }
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
        print("[Remove Observer - \(ObjectIdentifier(observer))]")
        observers[userId, default: []].removeAll(where: { $0.value === observer })
    }
}
