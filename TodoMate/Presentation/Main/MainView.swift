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
    
    let userInfo: AuthenticatedUser
    
    var body: some View {
        if userInfo.gid.isEmpty {
            unavailableView
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
    
    @ViewBuilder
    private var unavailableView: some View {
        ContentUnavailableView(label: {
            Label("그룹이 존재하지 않습니다", systemImage: "xmark")
        }) {
            Text("그룹에 우선 가입하세요.")
        } actions: {
            Button("로그아웃") {
                Task { await authManager.signOut() }
            }
            .padding(.top)
        }

    }
}

#Preview {
    MainView(userInfo: .stub)
        .environment(DIContainer.stub)
        .environment(AuthManager())
        .frame(width: 400, height: 400)
}
