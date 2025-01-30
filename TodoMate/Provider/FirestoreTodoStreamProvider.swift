//
//  FirestoreTodoStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

#if DEBUG
import Foundation
#endif

protocol TodoStreamProviderType {
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>>
}

final class FirestoreTodoStreamProvider: TodoStreamProviderType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
#if DEBUG
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: .now)
    private var startDateForDebug: Date { calendar.date(byAdding: .day, value: -4, to: today)! }
    private var endDateForDebug: Date { calendar.date(byAdding: .day, value: 3, to: today)! }
#endif
}
#if !PREVIEW
extension FirestoreTodoStreamProvider {
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
        AsyncStream { continuation in
            let listener = reference.todoCollection()
#if DEBUG
                /// Debug 모드일 때는 Todo 전체를 가져올 필요 없음
                .whereField("date", isGreaterThanOrEqualTo: startDateForDebug)
                .whereField("date", isLessThanOrEqualTo: endDateForDebug)
#endif
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching snapshots: \(error)")
                        }
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        guard let todoDTO = try? diff.document.data(as: TodoDTO.self) else { return }
                        
                        let todo = todoDTO.toModel()
                        
                        switch diff.type {
                        case .added:
                            continuation.yield(.added(todo))
                        case .modified:
                            continuation.yield(.modified(todo))
                        case .removed:
                            continuation.yield(.removed(todo))
                        }
                    }
                }
            
            continuation.onTermination = { @Sendable _ in
                /// 스트림이 종료될 때 리스너 해제
                print("[FirestoreTodoStreamProvider] - Stream Terminated")
                listener.remove()
            }
        }
    }
}
#else
extension FirestoreTodoStreamProvider {
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
        AsyncStream { continuation in
            for todo in Todo.stub {
                continuation.yield(.added(todo))
            }
            continuation.finish()
        }
    }
}
#endif
