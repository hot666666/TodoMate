//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 12/26/24.
//

import SwiftUI

struct MainView: View {
    @Environment(DIContainer.self) private var container
    @Environment(OverlayManager.self) private var overlayManager
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        ZStack {
            if authManager.authenticatedUser.gid.isEmpty {
                JoinGroupView()
            } else {
                GroupDashboardView(viewModel: .init(container: container,
                                                    userInfo: authManager.authenticatedUser))
                .disabled(!overlayManager.stack.isEmpty)
                .onDisappear {
                    overlayManager.reset()
                }
            }
            
            /// 오버레이 뷰 컨테이너(OverlayType)
            OverlayContainerView()
        }
    }
}

#Preview("Signed In") {
    MainView()
        .environment(DIContainer.stub)
        .environment(OverlayManager.stub)
        .environment(AuthManager.signedInAndHasGroupStub)
        .frame(width: 500, height: 400)
}

#Preview {
    MainView()
        .environment(DIContainer.stub)
        .environment(OverlayManager.stub)
        .environment(AuthManager.stub)
        .frame(width: 400, height: 400)
}
