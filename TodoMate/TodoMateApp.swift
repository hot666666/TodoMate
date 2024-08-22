//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import FirebaseCore

@main
struct TodoMateApp: App {
    @State private var appState: AppState
    @State private var container: DIContainer
    
    init() {
        FirebaseApp.configure()
        
        _appState = State(initialValue: AppState())
        _container = State(initialValue: DIContainer())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(container)
        }
    }
}
