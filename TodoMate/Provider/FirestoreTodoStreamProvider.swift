//
//  FirestoreTodoStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

import Foundation

final class FirestoreTodoStreamProvider: TodoStreamProviderType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
}
extension FirestoreTodoStreamProvider {
#if !PREVIEW
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
        AsyncStream { continuation in
            let streamCreatedTime: Date = .now
            
            let listener = reference.todoCollection()
                .whereField("lastModifiedAt", isGreaterThanOrEqualTo: streamCreatedTime)
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching snapshots: \(error)")
                        }
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        if let todoDTO = try? diff.document.data(as: TodoDTO.self),
                           let todo = try? todoDTO.toModel() {
                            switch diff.type {
                            case .added:
                                continuation.yield(.added(todo))
                            case .modified:
                                continuation.yield(.modified(todo))
                            case .removed:
                                continuation.yield(.removed(todo))
                            }
                        } else {
                            print("Error decoding and converting todo: \(diff.document.data())")
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
#else
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
        AsyncStream { continuation in
            let stream = self.reference.db.todoStream()
            let task = Task {
                for await change in stream {
                    if let todo = try? change.data.toModel() {
                        switch change {
                        case .added:
                            continuation.yield(.added(todo))
                        case .modified:
                            continuation.yield(.modified(todo))
                        case .removed:
                            continuation.yield(.removed(todo))
                        }
                    } else {
                        print("Error decoding and converting todo: \(change.data)")
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                print("[FirestoreTodoStreamProvider] - Stream Terminated")
                task.cancel()
                self.reference.db.todoStreamTermination()
            }
        }
    }
#endif
}
