//
//  FirebaseTodoRepository.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation
import Firebase

protocol TodoRepositoryType {
    func createTodo(todo: TodoDTO) async throws
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO]
    func updateTodo(todo: TodoDTO) async throws
    func deleteTodo(todoId: String) async throws
    func observeTodoChanges() -> AsyncStream<DatabaseChange<TodoDTO>>
}

class FirebaseTodoRepository: TodoRepositoryType {
    private let reference: FirebaseDatabaseReference
    
    init(reference: FirebaseDatabaseReference = .shared) {
        self.reference = reference
    }
}

extension FirebaseTodoRepository {
    func observeTodoChanges() -> AsyncStream<DatabaseChange<TodoDTO>> {
        AsyncStream { continuation in
            let handle = reference.todoReference().observe(.childChanged) { snapshot in
                do {
                    let todo = try self.reference.decode(from: snapshot, type: TodoDTO.self)
                    continuation.yield(.modified(todo))
                } catch {
                    print("Error decoding todo: \(error)")
                }
            }
            
            let addedHandle = reference.todoReference().observe(.childAdded) { snapshot in
                do {
                    let todo = try self.reference.decode(from: snapshot, type: TodoDTO.self)
                    continuation.yield(.added(todo))
                } catch {
                    print("Error decoding added todo: \(error)")
                }
            }
            
            let removedHandle = reference.todoReference().observe(.childRemoved) { snapshot in
                do {
                    let todo = try self.reference.decode(from: snapshot, type: TodoDTO.self)
                    continuation.yield(.removed(todo))
                } catch {
                    print("Error decoding removed todo: \(error)")
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                self.reference.todoReference().removeObserver(withHandle: handle)
                self.reference.todoReference().removeObserver(withHandle: addedHandle)
                self.reference.todoReference().removeObserver(withHandle: removedHandle)
            }
        }
    }
}

extension FirebaseTodoRepository {
    func createTodo(todo: TodoDTO) async throws {
        let newTodoRef = reference.todoReference().childByAutoId()
        var newTodo = todo
        newTodo.id = newTodoRef.key
        
        do {
            try await newTodoRef.setValue(newTodo)
        } catch {
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        do {
            let snapshot = try await reference.todoReference()
                .queryOrdered(byChild: "date")
                .queryStarting(atValue: startDate.timeIntervalSince1970)
                .queryEnding(atValue: endDate.timeIntervalSince1970)
                .queryEqual(toValue: userId, childKey: "uid")
                .getData()
            
            guard snapshot.exists(), let children = snapshot.children.allObjects as? [DataSnapshot] else {
                throw FirebaseRepositoryError.invalidSnapshotError
            }
            
            return try children.map { child in
                try reference.decode(from: child, type: TodoDTO.self)
            }
        } catch {
            print("Error fetching todos: \(error)")
            throw FirebaseRepositoryError.decodingError
        }
    }
    
    func updateTodo(todo: TodoDTO) async throws {
        guard let todoId = todo.id else {
            throw NSError(domain: "FirebaseTodoRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Todo ID is missing"])
        }
        
        do {
            try await reference.todoReference().child(todoId).setValue(todo)
        } catch {
            print("Error updating todo: \(error)")
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func deleteTodo(todoId: String) async throws {
        do {
            try await reference.todoReference().child(todoId).removeValue()
        } catch {
            throw FirebaseRepositoryError.removeValueError
        }
    }
}
