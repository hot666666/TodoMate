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
    private var observers: [String: [TodoObserver]] = [:]
    
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
        observers[userId, default: []].append(observer)
    }
    
    func removeObserver(_ observer: TodoObserver, for userId: String) {
        if observers[userId, default: []].contains(where: { ObjectIdentifier($0) == ObjectIdentifier(observer) }) {
            print("[Remove Observer - \(ObjectIdentifier(observer))]")
        }
        observers[userId, default: []].removeAll(where: { ObjectIdentifier($0) == ObjectIdentifier(observer) })
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
                observer.todoAdded(todo)
            }
        case .modified:
            for observer in observers {
                observer.todoModified(todo)
            }
        case .removed:
            for observer in observers {
                observer.todoRemoved(todo)
            }
        }
    }
}
