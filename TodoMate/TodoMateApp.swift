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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        .commands {
            CommandGroup(after: .appInfo) {
                Button("업데이트 확인") {
                    appDelegate.openCheckAppUpdateView()
                }
                .keyboardShortcut("U", modifiers: .command)
            }
        }
    }
}
