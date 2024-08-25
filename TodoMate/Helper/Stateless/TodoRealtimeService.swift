//
//  TodoManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI
import FirebaseFirestore

class TodoRealtimeService: TodoRealtimeServiceType {
    private let todoRepository: TodoRepositoryType
    private var task: Task<Void, Never>?
    private var observers: [String: [WeakTodoObserver]] = [:]
    
    init(todoRepository: TodoRepositoryType = FirestoreTodoRepository(reference: .shared)) {
        self.todoRepository = todoRepository
        setupRealtimeUpdates()
    }
    
    deinit {
        task?.cancel()
    }
}

extension TodoRealtimeService {
    func addObserver(_ observer: TodoObserver, for userId: String) {
        print("[Add Observer - \(ObjectIdentifier(observer))]")
        observers[userId, default: []].append(WeakTodoObserver(observer))
    }
    
    func removeObserver(_ observer: TodoObserver, for userId: String) {
        if observers[userId, default: []].contains(where: { $0.value === observer }) {
            print("[Remove Observer - \(ObjectIdentifier(observer))]")
        }
        observers[userId, default: []].removeAll(where: { $0.value === observer })
    }
}

extension TodoRealtimeService {
    private func setupRealtimeUpdates() {
        task = Task {
            for await change in todoRepository.observeTodoChanges() {
                if !observers.isEmpty {
                    print("[Observed Todo change in FirebaseFirestore] - ", change)
                    handleDatabaseChange(change)
                }
            }
        }
    }
    
    private func handleDatabaseChange(_ change: DatabaseChange<TodoDTO>) {
        let todo = change.todoDTO.toModel()
        guard let observers = observers[todo.uid], !observers.isEmpty else {
            print("[No Observer exists]")
            return
        }
        
        switch change {
        case .added:
            for observer in observers {
                observer.value?.todoAdded(todo)
            }
        case .modified:
            for observer in observers {
                observer.value?.todoModified(todo)
            }
        case .removed:
            for observer in observers {
                observer.value?.todoRemoved(todo)
            }
        }
    }
}

fileprivate class WeakTodoObserver {
    weak var value: TodoObserver?
    
    init(_ observer: TodoObserver) {
        self.value = observer
    }
}
