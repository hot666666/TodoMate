//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 12/26/24.
//

import SwiftUI

struct MainView: View {
    @Environment(DIContainer.self) private var container
    
    let userInfo: AuthenticatedUser
    
    var body: some View {
        if userInfo.gid.isEmpty {
            JoinGroupView()
        } else {
            groupDashboardView
        }
    }
    
    @ViewBuilder
    private var groupDashboardView: some View {
        OverlayContainer {
            GroupDashboardView(viewModel: .init(container: container, userInfo: userInfo))
        }
    }
}

#Preview {
    MainView(userInfo: .stub)
        .environment(DIContainer.stub)
        .frame(width: 400, height: 400)
}
