//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

@main
struct TodoMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            _TodoMateApp()
        }
    }
}

fileprivate struct _TodoMateApp: View {
    @State private var overlayManager: OverlayManager = .init()

    // TODO: - DIContainer의 stub을 제거하고, 실제 서비스를 주입
    @State private var container: DIContainer
    @State private var authManager: AuthManager
    
    init() {
        let container: DIContainer = .init(
            userService: UserService(),
            todoService: StubTodoService()
        )
        self._container = State(initialValue: container)
        self._authManager = State(initialValue: AuthManager(userService: container.userService))
    }
    
    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainView()
                    .environment(overlayManager)
                    .environment(container)
            } else {
                AuthView()
            }
        }
        .environment(authManager)
    }
}

#Preview {
    _TodoMateApp()
        .frame(width: 400, height: 400)
}
