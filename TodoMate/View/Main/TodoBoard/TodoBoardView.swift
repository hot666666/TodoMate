//
//  TodoBoardView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct TodoBoardView: View {
    @Environment(DIContainer.self) private var container
    @State private var viewModel: TodoBoardViewModel
    
    init(viewModel: TodoBoardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ForEach(viewModel.users) { user in
                todoBox(for: user)
            }
            
            if viewModel.users.isEmpty {
                placeholder
            }
            
            Spacer(minLength: 50)
        }
        .task {
            await viewModel.fetchGroupUser()
            await viewModel.observeChanges()
        }
    }
    
    @ViewBuilder
    private func todoBox(for user: User) -> some View {
        ExpandableView(
            storageKey: user.uid,
            title: {
                TodoBoxTitleView(nickname: user.nickname) {
                    ProfileButton(user: user,
                                  isMe: viewModel.isMe(user),
                                  updateGroup: viewModel.fetchGroupUser)
                }
            },
            content: {
                TodoBoxView(
                    viewModel: .init(
                        container: container,
                        user: user,
                        isMine: viewModel.isMe(user),
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
            .opacity(0.7)
    }
}

// MARK: - ProfileButton
fileprivate struct ProfileButton: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let user: User
    let isMe: Bool
    let updateGroup: () async -> Void
    
    var body: some View {
        Button(action: {
            overlayManager.push(.profile(user, updateGroup: updateGroup))
        }) {
            Image(systemName: "gearshape.fill")
        }
        .hoverButtonStyle2()
        .opacity(isMe ? 0.7 : 0)
    }
}
    
// MARK: - TodoBoxTitleView
fileprivate struct TodoBoxTitleView<ProfileButton: View>: View {
    let nickname: String
    let profileButton: () -> ProfileButton
    
    var body: some View {
        HStack {
            Text(nickname)
            Spacer()
            profileButton()
                .padding(.trailing, 20)
        }
    }
}


#Preview {
    ScrollView {
        VStack{
            TodoBoardView(viewModel: .init(container: DIContainer.stub,
                                           userInfo: UserInfo.stub))
            Spacer()
        }
    }
    .environment(DIContainer.stub)
    .environment(AuthManager.stub)
    .environment(OverlayManager.stub)
    .frame(width: 400, height: 600)
}
