//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct TodoMateApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    @Environment(\.scenePhase) private var scenePhase
    
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
                .onChange(of: scenePhase) {
                    /// 화면 상태 비활성화 시, 현재 context 저장 및 위젯 갱신
                    if $1 != .active {
                        try? sharedModelContainer.mainContext.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
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
        let container: DIContainer = .init(modelContainer: modelContainer)
#endif
        self._container = State(initialValue: container)
        self._authManager = State(initialValue: AuthManager(userService: container.userService,
                                                            userInfoService: container.userInfoService,
                                                            modelContainer: modelContainer))
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
