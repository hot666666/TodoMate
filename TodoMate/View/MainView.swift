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
        ZStack {
            ScrollView {
                GroupDashboardView(viewModel: .init(container: container,
                                                    userInfo: authManager.userInfo))
                
                // TODO: - REMOVE
                SignOutButton()
            }
            
            /// 오버레이 뷰 컨테이너(OverlayType)
            OverlayContainerView()
        }
    }
}

#Preview {
    MainView()
        .environment(DIContainer.stub)
        .environment(OverlayManager.stub)
        .environment(AuthManager.stub)
        .frame(width: 400, height: 400)
}
