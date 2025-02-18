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
            #if DEBUG
                /// whereField는 해당 조건에 맞는 데이터에 대해서만 업데이트를 처리하지만, 이 조건 밖의 데이터가 이 조건에 맞게 변경되어도 업데이트를 처리하지 않는다
                /// 앱이 초기화 된 상태에서는 다시 데이터를 전부 불러오기 때문에 3일 전 데이터까지만 불러온다
                .whereField("date", isGreaterThanOrEqualTo: streamCreatedTime.addingTimeInterval(-60*60*24*3))
            #endif
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching snapshots: \(error)")
                        }
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        if let todoDTO = try? diff.document.data(as: TodoDTO.self),
                           todoDTO.lastModifiedAt >= streamCreatedTime,
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
