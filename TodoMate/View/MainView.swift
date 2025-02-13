//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 12/26/24.
//

import SwiftUI

struct MainView: View {
    @Environment(DIContainer.self) private var container
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        if authManager.authenticatedUser.gid.isEmpty {
            JoinGroupView()
        } else {
            groupDashboardView
        }
    }
    
    @ViewBuilder
    private var groupDashboardView: some View {
        OverlayContainer {
            GroupDashboardView(viewModel: .init(container: container,
                                                userInfo: authManager.authenticatedUser))
        }
    }
}

#Preview("Signed In") {
    MainView()
        .environment(DIContainer.stub)
        .environment(AuthManager.signedInAndHasGroupStub)
        .frame(width: 500, height: 400)
}

#Preview {
    MainView()
        .environment(DIContainer.stub)
        .frame(width: 400, height: 400)
}
