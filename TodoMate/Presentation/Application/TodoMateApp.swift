//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData
import WidgetKit
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
        .windowStyle(.hiddenTitleBar)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else { return }
            try? sharedModelContainer.mainContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

fileprivate struct _TodoMateApp: View {
    @State private var container: DIContainer
    @State private var authManager: AuthManager
    
    init(modelContainer: ModelContainer) {
#if PREVIEW
        let container: DIContainer = .init(
            authService: StubAuthService(),
            googleSignInService: StubGoogleSignInService(),
            widgetDataManager: WidgetDataManager(modelContainer: modelContainer),
            userService: StubUserService(),
            todoService: TodoService(),  /// 테스트용 reference 구현
            chatService: StubChatService(),
            groupService: StubGroupService(),
            chatStreamProvider: FirestoreChatStreamProvider(),
            todoStreamProvider: FirestoreTodoStreamProvider(),  /// 테스트용 reference 구현
            userInfoService: UserInfoService(),  /// 외부에서 저장위치(UserDefualt key) 설정
            todoOrderService: StubTodoOrderService())  /// 외부에서 저장위치(UserDefualt key) 설정
#else
        // TODO: - 의존성 순서 리팩토링
        let userService: UserService = UserService()
        let googleSignInService: GoogleSignInService = GoogleSignInService()
        
        let container: DIContainer = .init(
            authService: AuthService(userService: userService, googleSignInService: googleSignInService),
            googleSignInService: googleSignInService,
            widgetDataManager: WidgetDataManager(modelContainer: modelContainer),
            userService: userService,
            todoService: TodoService(),
            chatService: ChatService(),
            groupService: GroupService(),
            chatStreamProvider: FirestoreChatStreamProvider(),
            todoStreamProvider: FirestoreTodoStreamProvider(),
            userInfoService: UserInfoService(),
            todoOrderService: TodoOrderService())
#endif
        self._container = State(initialValue: container)
        self._authManager = State(initialValue: AuthManager(authenticationUseCase: container.authenticationUseCase, fetchAuthenticatedUserUseCase: container.fetchAuthenticatedUserUseCase))
    }
    
    var body: some View {
        content
            .environment(authManager)
    }
    
    @ViewBuilder
    private var content: some View {
        switch authManager.state {
        case .signedOut:
            AuthView()
        case .signedIn(let signedInUser):
            MainView(userInfo: signedInUser)
                .environment(container)
        case .loading:
            ProgressView()
        }
    }
}

#Preview {
    _TodoMateApp(modelContainer: .forPreview())
}
