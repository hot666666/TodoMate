//
//  WidgetDataManager.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import SwiftData
import Foundation
import WidgetKit

protocol WidgetDataManagerType {
    func save(_ todo: WidgetTodo) async
    func remove(_ todoFid: String) async
    func removeAll () async
}

final class WidgetDataManager: WidgetDataManagerType {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // Save(or Update) WidgetTodo
    @MainActor
    func save(_ todo: WidgetTodo) async {
        let todoFid = todo.fid
        let fetchDescriptor = FetchDescriptor<WidgetTodo>(predicate: #Predicate { $0.fid == todoFid })
        do {
            let context = modelContainer.mainContext
            if let existingEntity = try context.fetch(fetchDescriptor).first {
                existingEntity.date = todo.date
                existingEntity.content = todo.content
                return
            }
            context.insert(todo)
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            print("New TodoEntity inserted with fid \(todo.fid)")
        } catch {
            print("Error checking for existing TodoEntity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func remove(_ todoFid: String) async {
        let fetchDescriptor = FetchDescriptor<WidgetTodo>(predicate: #Predicate { $0.fid == todoFid })
        do {
            let context = modelContainer.mainContext
            guard let existingEntity = try context.fetch(fetchDescriptor).first else {
                print("No TodoEntity found with fid \(todoFid)")
                return
            }
            context.delete(existingEntity)
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            print("TodoEntity removed")
        } catch {
            print("Error removing TodoEntity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func removeAll() async {
        let modelContext = modelContainer.mainContext
        modelContext.container.deleteAllData()
    }
}
