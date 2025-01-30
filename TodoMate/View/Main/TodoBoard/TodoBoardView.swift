//
//  TodoBoardView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct TodoBoardView: View {
    @Environment(DIContainer.self) private var container
    @Environment(OverlayManager.self) private var overlayManager
    @State private var viewModel: TodoBoardViewModel
    private let updateGroup: () async -> Void
    var users: [User]
    
    init(viewModel: TodoBoardViewModel, users: [User], updateGroup: @escaping () async -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.users = users
        self.updateGroup = updateGroup
    }
    
    var body: some View {
        VStack {
            ForEach(users) { user in
                todoBox(for: user)
            }
            
            if users.isEmpty {
                placeholder
            }
            
            Spacer(minLength: 20)
        }
        .task {
            await viewModel.observeChanges()
        }
    }
    
    @ViewBuilder
    private func todoBox(for user: User) -> some View {
        ExpandableView(
            storageKey: user.uid,
            title: {
                TodoBoxTitleView(
                    user: user,
                    currentUserId: viewModel.userInfo.id,
                    onSettingsTap: {
                        overlayManager.push(.profile(user, updateGroup: updateGroup))
                    }
                )
            },
            content: {
                TodoBoxView(
                    viewModel: .init(
                        container: container,
                        user: user,
                        userInfo: viewModel.userInfo,
                        onAppear: viewModel.addObserver,
                        onDisappear: viewModel.removeObserver
                    )
                )
                .padding(.horizontal, 20)
            }
        )
    }
    
    @ViewBuilder
    private var placeholder: some View {
        ReadonlyTodoList(todos: [])
            .opacity(0.6)
    }
}

fileprivate struct TodoBoxTitleView: View {
    let user: User
    let currentUserId: String
    let onSettingsTap: () -> Void
    
    var body: some View {
        HStack {
            Text(user.nickname)
            Spacer()
            if user.uid == currentUserId {
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                }
                .hoverButtonStyle2()
                .opacity(0.7)
                .padding(.trailing, 20)
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack{
            TodoBoardView(viewModel: .init(container: .stub,
                                           userInfo: AuthManager.UserInfo.stub),
                          users: User.stub,
                          updateGroup: {})
                                           
            Spacer()
        }
    }
    .environment(DIContainer.stub)
    .environment(AuthManager.stub)
    .environment(OverlayManager.stub)
    .frame(width: 400, height: 600)
}
