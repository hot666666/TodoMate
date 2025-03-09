//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 3/3/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(DIContainer.self) private var container
    
    // TODO: - GroupDashboard에서 그룹 유저를 패치하는 문제
    let userInfo: AuthenticatedUser
    let groupUsers: [User]
    
    var body: some View {
        ScrollView {
            VStack {
                ChatBoardView(viewModel: .init(container: container, userInfo: userInfo))
                TodoBoardView(viewModel: .init(container: container, userInfo: userInfo),
                              users: groupUsers)
            }
            .padding(.horizontal)
        }
    }
}
