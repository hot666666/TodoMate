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
    #if PREVIEW
        @State private var container: DIContainer = .stub
    #else
        // TODO: - DIContainer의 stub을 제거하고, 실제 서비스를 주입
    @State private var container: DIContainer = .init
    #endif
    @State private var overlayManager: OverlayManager = .init()
    
    var body: some View {
        MainView()
            .environment(container)
            .environment(overlayManager)
            .frame(minWidth: 400, minHeight: 400)
    }
}

#Preview {
    _TodoMateApp()
        .frame(width: 400, height: 400)
}
