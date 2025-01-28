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
    var users: [User]
    
    init(viewModel: TodoBoardViewModel, users: [User]) {
        self._viewModel = State(initialValue: viewModel)
        self.users = users
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
        ExpandableView(title: user.nickname, storageKey: user.uid) {
            TodoBoxView(viewModel: .init(container: container,
                                         user: user,
                                         userInfo: viewModel.userInfo,
                                         onAppear: viewModel.addObserver,
                                         onDisappear: viewModel.removeObserver))
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var placeholder: some View {
        ReadonlyTodoList(todos: [])
            .opacity(0.6)
    }
}

#Preview {
    ScrollView {
        VStack{
            TodoBoardView(viewModel: .init(container: .stub,
                                           userInfo: AuthManager.UserInfo.stub),
                          users: User.stub)
                                           
            Spacer()
        }
    }
    .environment(DIContainer.stub)
    .environment(AuthManager.stub)
    .environment(OverlayManager.stub)
    .frame(width: 400, height: 600)
}
