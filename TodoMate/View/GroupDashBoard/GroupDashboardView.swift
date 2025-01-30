//
//  GroupDashboardView.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import SwiftUI

struct GroupDashboardView: View {
    @Environment(DIContainer.self) private var container
    @Environment(AuthManager.self) private var authManager
    @State private var viewModel: GroupDashboardViewModel
    
    init(viewModel: GroupDashboardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ChatBoardView(viewModel: .init(container: container,
                                           userInfo: authManager.userInfo))
            TodoBoardView(viewModel: .init(container: container,
                                           userInfo: authManager.userInfo),
                          users: viewModel.users)
        }
        .task {
            await viewModel.fetchUser()
        }
    }
}

#Preview {
    ScrollView {
        GroupDashboardView(viewModel: .init(container: .stub, userInfo: .stub))
            .environment(AuthManager.stub)
            .environment(DIContainer.stub)
            .environment(OverlayManager.stub)
    }
    .frame(width: 400, height: 400)
    
}
