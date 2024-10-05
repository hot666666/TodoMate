//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData
import WidgetKit
import FirebaseFirestore
import FirebaseCore

@main
struct TodoMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppState
    @State private var container: DIContainer
    
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoEntity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            FirebaseApp.configure()
        }
        
        _appState = State(initialValue: AppState())
        _container = State(initialValue: DIContainer(chatService: ChatService(),
                                                     todoService: TodoService(),
                                                     todoRealtimeService: TodoRealtimeService(modelContainer: sharedModelContainer),
                                                     imageUploadService: ImageUploadService()))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(container)
                .onChange(of: scenePhase, { _, newValue in
                    if newValue != .active {
                        try? sharedModelContainer.mainContext.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                })
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Check for Updates") {
                    appDelegate.checkForUpdates()
                }
            }
        }
    }
}
