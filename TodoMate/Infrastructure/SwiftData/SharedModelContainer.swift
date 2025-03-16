//
//  SharedModelContainer.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//

import SwiftData

enum SharedModelContainer {
  static func create() -> ModelContainer {
    let schema = Schema([WidgetTodo.self])

    #if DEBUG || PREVIEW
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    #else
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    #endif

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }
}
