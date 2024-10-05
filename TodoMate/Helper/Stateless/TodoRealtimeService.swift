//
//  TodoManager.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI
import SwiftData
import FirebaseFirestore

class TodoRealtimeService: TodoRealtimeServiceType {
    private let todoRepository: TodoRepositoryType
    private let modelContainer: ModelContainer
    private var task: Task<Void, Never>?
    private var observers: [String: [WeakTodoObserver]] = [:]
    
    init(modelContainer: ModelContainer, todoRepository: TodoRepositoryType = FirestoreTodoRepository(reference: .shared)) {
        self.modelContainer = modelContainer
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
                    await handleDatabaseChange(change)
                }
            }
        }
    }
    
    private func handleDatabaseChange(_ change: DatabaseChange<TodoDTO>) async {
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
            /// 위젯 데이터 - 진행 중이면 추가, 아니면 삭제
            if todo.status == .inProgress {
                await saveToModelContainer(todo.toEntity())
            } else {
                await deleteFromModelContainer(todo.fid)
            }
            ///
            
            for observer in observers {
                observer.value?.todoModified(todo)
            }
        case .removed:
            /// 위젯 데이터 - 존재하면 삭제
            await deleteFromModelContainer(todo.fid)
            ///
            
            for observer in observers {
                observer.value?.todoRemoved(todo)
            }
        }
    }
}

extension TodoRealtimeService {
    @MainActor
    private func saveToModelContainer(_ entity: TodoEntity) {
        let context = modelContainer.mainContext
        context.insert(entity)
    }
    
    @MainActor
    private func deleteFromModelContainer(_ todoId: String?) {
        guard let todoId else { return }
        
        let context = modelContainer.mainContext
        let fetchDescriptor = FetchDescriptor<TodoEntity>(predicate: #Predicate { $0.fid == todoId })
        if let existingEntity = try? context.fetch(fetchDescriptor).first {
            context.delete(existingEntity)
        }
    }
}

fileprivate class WeakTodoObserver {
    weak var value: TodoObserver?
    
    init(_ observer: TodoObserver) {
        self.value = observer
    }
}
