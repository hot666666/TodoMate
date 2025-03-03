//
//  LocalDataManager.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import SwiftData
import Foundation

protocol WidgetDataManagerType {
    func save(_ todo: WidgetTodo) async
    func remove(_ todoFid: String?) async
    func removeAll () async
}

final class WidgetDataManager: WidgetDataManagerType {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func save(_ todo: WidgetTodo) async {
        // Save(Update) TodoEntity
        
        guard let fid = todo.fid else {
            print("TodoEntity has no fid")
            return
        }
        
        let context = modelContainer.mainContext
        
        let fetchDescriptor = FetchDescriptor<WidgetTodo>(predicate: #Predicate { $0.fid == fid })
        do {
            if let existingEntity = try context.fetch(fetchDescriptor).first {
                existingEntity.date = todo.date
                existingEntity.content = todo.content
                return
            }
            context.insert(todo)
            print("New TodoEntity inserted with fid \(fid)")
        } catch {
            print("Error checking for existing TodoEntity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func remove(_ todoFid: String?) async {
        guard let todoFid else { return }
        
        let context = modelContainer.mainContext
        
        let fetchDescriptor = FetchDescriptor<WidgetTodo>(predicate: #Predicate { $0.fid == todoFid })
        if let existingEntity = try? context.fetch(fetchDescriptor).first {
            context.delete(existingEntity)
            print("TodoEntity removed")
        }
    }
    
    @MainActor
    func removeAll() async {
        let modelContext = modelContainer.mainContext
        modelContext.container.deleteAllData()
    }
}
