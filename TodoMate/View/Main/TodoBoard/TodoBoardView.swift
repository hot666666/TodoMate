//
//  TodoBoardView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

// MARK: - TodoBoardView
struct TodoBoardView: View {
    @Environment(DIContainer.self) private var container
    @State private var viewModel: TodoBoardViewModel
    
    init(viewModel: TodoBoardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ForEach(viewModel.users) { user in
                UserTodoSection(
                    user: user,
                    isMe: viewModel.isMe(user),
                    onUpdateGroup: viewModel.fetchGroupUser,
                    addObserver: viewModel.addObserver,
                    removeObserver: viewModel.removeObserver
                )
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
    private var placeholder: some View {
        GroupBox {
            VStack(alignment: .leading) {
                Label("오늘의 투두", systemImage: "list.dash")
                Divider()
                    .padding(.bottom)
            }
            .padding(5)
        }
        .opacity(0.7)
        .padding(.horizontal, 20)
    }
}

// MARK: - UserTodoSection
fileprivate  struct UserTodoSection: View {
    @Environment(DIContainer.self) private var container
    
    let user: User
    let isMe: Bool
    let onUpdateGroup: () async -> Void
    let addObserver: (TodoObserverType, String) -> Void
    let removeObserver: (TodoObserverType, String) -> Void
    
    var body: some View {
        ExpandableView(
            storageKey: user.uid,
            header: { sectionHeader },
            content: { todoBoxContent }
        )
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Text(user.nickname)
            Spacer()
        }
    }
    
    @ViewBuilder
    private var sectionHeader: some View {
        header
            .overlay(alignment: .topTrailing) {
                ProfileButton(user: user, updateGroup: onUpdateGroup)
                    .opacity(isMe ? 1 : 0)
            }
    }
    
    @ViewBuilder
    private var todoBoxContent: some View {
        TodoBoxView(
            viewModel: .init(
                container: container,
                user: user,
                isMine: isMe,
                onAppear: addObserver,
                onDisappear: removeObserver
            )
        )
    }
}

// MARK: - ProfileButton
fileprivate struct ProfileButton: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let user: User
    let updateGroup: () async -> Void
    
    var body: some View {
        Button(action: {
            overlayManager.push(.profile(user, updateGroup: updateGroup))
        }) {
            Image(systemName: "gearshape.fill")
        }
        .hoverButtonStyle2()
        .padding(.trailing, 20)
    }
}


#Preview {
    ScrollView {
        VStack{
            TodoBoardView(viewModel: .init(container: DIContainer.stub, userInfo: AuthenticatedUser.stub))
            Spacer()
        }
    }
    .environment(DIContainer.stub)
    .environment(AuthManager.stub)
    .environment(OverlayManager.stub)
    .frame(width: 400, height: 600)
}
