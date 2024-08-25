//
//  TodoMatePreviewApp.swift
//  TodoMatePreview
//
//  Created by hs on 8/17/24.
//

import SwiftUI

@main
struct TodoMatePreviewApp: App {
    @State private var appState: AppState
    @State private var container: DIContainer
    
    init() {
        _appState = State(initialValue: AppState())
        _container = State(initialValue: DIContainer.stub)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(container)
        }
    }
}
