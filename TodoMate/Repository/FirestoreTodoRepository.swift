//
//  TodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import FirebaseFirestore

enum DatabaseChange<T> {
    case added(T)
    case modified(T)
    case removed(String)
}

protocol TodoRepository {
    func fetchTodos() async throws -> [TodoDTO]
    func createTodo(todo: TodoDTO) async throws
    func updateTodo(todo: TodoDTO) async throws
    func deleteTodo(todoId: String) async throws
    func observeTodoChanges() -> AsyncStream<DatabaseChange<TodoDTO>>
}

class FirestoreTodoRepository: TodoRepository {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
    func observeTodoChanges() -> AsyncStream<DatabaseChange<TodoDTO>> {
        AsyncStream { continuation in
            let listener = reference.todoCollection().addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    if let error = error {
                        print("Error fetching snapshots: \(error)")
                    }
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    if let todoDTO = try? diff.document.data(as: TodoDTO.self) {
                        switch diff.type {
                        case .added:
                            continuation.yield(.added(todoDTO))
                        case .modified:
                            continuation.yield(.modified(todoDTO))
                        case .removed:
                            continuation.yield(.removed(diff.document.documentID))
                        @unknown default:
                            break
                        }
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }
}

extension FirestoreTodoRepository {
    func fetchTodos() async throws -> [TodoDTO] {
        let snapshot = try await reference.todoCollection().getDocuments()
        return snapshot.documents.compactMap { document -> TodoDTO? in
            do {
                return try document.data(as: TodoDTO.self)
            } catch {
                print("Error decoding todo: \(error)")
                return nil
            }
        }
    }
    
    func createTodo(todo: TodoDTO) async throws {
        let todoDocRef = reference.todoCollection().document()
        var newTodo = todo
        newTodo.id = todoDocRef.documentID
        try todoDocRef.setData(from: newTodo)
    }

    func updateTodo(todo: TodoDTO) async throws {
        guard let todoId = todo.id else { return }
        let todoDocRef = reference.todoCollection().document(todoId)
        try todoDocRef.setData(from: todo)
    }
    
    func deleteTodo(todoId: String) async throws {
        let todoDocRef = reference.todoCollection().document(todoId)
        try await todoDocRef.delete()
    }
}
