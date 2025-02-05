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
            for todo in Todo.stub {
                continuation.yield(.added(todo))
            }
            print("[FirestoreTodoStreamProvider] - Stream Terminated")
            continuation.finish()
        }
    }
}
