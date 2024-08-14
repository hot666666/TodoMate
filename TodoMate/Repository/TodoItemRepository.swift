//
//  TodoItemRepository.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftData
import SwiftUI

class TodoItemRepository {
    // Create -> fetch
    func createTodoItem(modelContext: ModelContext) {
        modelContext.insert(TodoItemEntity())
        saveContext(modelContext)
    }
    
    // Read - ALL
    func fetchAllTodoItems(modelContext: ModelContext) -> [TodoItem] {
        let fetchDescriptor = FetchDescriptor<TodoItemEntity>()
        do {
            let entities = try modelContext.fetch(fetchDescriptor)
            return entities.map { $0.toModel() }
        } catch {
            print("Failed to fetch todo items: \(error)")
            return []
        }
    }
    
    // Read - id
    func fetchTodoItem(modelContext: ModelContext, byID id: PersistentIdentifier) -> TodoItem? {
        let fetchDescriptor = FetchDescriptor<TodoItemEntity>(predicate: #Predicate { $0.persistentModelID == id })
        do {
            if let entity = try modelContext.fetch(fetchDescriptor).first {
                return entity.toModel()
            }
        } catch {
            print("Failed to fetch todo item by ID: \(error)")
        }
        return nil
    }
    
    // Update
    func updateTodoItem(modelContext: ModelContext, _ item: TodoItem) {
        guard let id = item.pid else { return }
        let fetchDescriptor = FetchDescriptor<TodoItemEntity>(predicate: #Predicate { $0.persistentModelID == id })
        do {
            if let entity = try modelContext.fetch(fetchDescriptor).first {
                entity.content = item.content
                entity.date = item.date
                entity.detail = item.detail
                entity.statusRawValue = item.status.rawValue
                entity.startTime = item.startTime
                entity.endTime = item.endTime
                
                saveContext(modelContext)
            }
        } catch {
            print("Failed to update todo item: \(error)")
        }
    }
    
    // Delete
    func deleteTodoItem(modelContext: ModelContext, byID id: PersistentIdentifier) {
        let fetchDescriptor = FetchDescriptor<TodoItemEntity>(predicate: #Predicate { $0.persistentModelID == id })
        do {
            if let entity = try modelContext.fetch(fetchDescriptor).first {
                modelContext.delete(entity)
                saveContext(modelContext)
            }
        } catch {
            print("Failed to delete todo item: \(error)")
        }
    }
}

extension TodoItemRepository {
    private func saveContext(_ modelContext: ModelContext) {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
