//
//  ModelContainer+Extension.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

import SwiftData

extension ModelContainer {
    static func forPreview() -> ModelContainer {
        let schema = Schema([TodoEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory ModelContainer for preview: \(error)")
        }
    }
}
