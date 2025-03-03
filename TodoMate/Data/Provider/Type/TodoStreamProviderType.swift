//
//  FirestoreTodoStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

protocol TodoStreamProviderType {
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>>
}

class StubTodoStreamProvider: TodoStreamProviderType {
    func createTodoStream() -> AsyncStream<DatabaseChange<Todo>> {
        
        AsyncStream { continuation in
            print("[FirestoreTodoStreamProvider] - Stream Created")
            
            for todo in Todo.stub {
                continuation.yield(.added(todo))
            }
            
            let task = Task {
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: 10_000_000_000)
                        print("[FirestoreTodoStreamProvider] - Listening...")
                    } catch {
                        // 취소 에러 발생 시 루프 종료
                        break
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                print("[FirestoreTodoStreamProvider] - Stream Terminated")
                task.cancel()
            }
        }
    }
}
