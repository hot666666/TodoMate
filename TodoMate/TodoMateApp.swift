//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

@main
struct TodoMateApp: App {
    @State private var appState: AppState = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: TodoItemEntity.self)
                .environment(appState)
        }
    }
}

