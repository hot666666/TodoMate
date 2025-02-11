//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct TodoMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        /// 앱 시작 시 가장 처음 Firebase 초기화 진행 보장
        FirebaseApp.configure()
    }
    
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([TodoEntity.self])
#if PREVIEW
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
#else
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
#endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            _TodoMateApp(modelContainer: sharedModelContainer)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("업데이트") {
                    appDelegate.checkForUpdates()
                }
            }
        }
    }
}

fileprivate struct _TodoMateApp: View {
    @State private var container: DIContainer
    @State private var authManager: AuthManager
    @State private var overlayManager: OverlayManager = .init()
    
    init(modelContainer: ModelContainer) {
#if PREVIEW
        let container: DIContainer = .stub
#else
        let container: DIContainer = .init(modelContainer: modelContainer,
                                           userService: UserService(),
                                           todoService: TodoService(),
                                           chatService: ChatService(),
                                           groupService: GroupService(),
                                           chatStreamProvider: FirestoreChatStreamProvider(),
                                           todoStreamProvider: FirestoreTodoStreamProvider(),
                                           userInfoService: UserInfoService(),
                                           todoOrderService: TodoOrderService())
#endif
        self._container = State(initialValue: container)
        self._authManager = State(initialValue: AuthManager(container: container))
    }
    
    var body: some View {
        content
            .environment(authManager)
    }
    
    @ViewBuilder
    private var content: some View {
        switch authManager.authState {
        case .signedOut:
            AuthView()
        case .signedIn:
            MainView()
                .environment(overlayManager)
                .environment(container)
        case .loading:
            ProgressView()
        }
    }
}

#Preview {
    _TodoMateApp(modelContainer: .forPreview())
}
