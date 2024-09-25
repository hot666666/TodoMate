//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseCore

@main
struct TodoMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState: AppState
    @State private var container: DIContainer
    
    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            FirebaseApp.configure()
        }
        
        _appState = State(initialValue: AppState())
        _container = State(initialValue: DIContainer(chatService: ChatService(),
                                                     todoService: TodoService(),
                                                     todoRealtimeService: TodoRealtimeService(),
                                                     imageUploadService: ImageUploadService()))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(container)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Check for Updates") {
                    appDelegate.checkForUpdates()
                }
            }
        }    }
}
