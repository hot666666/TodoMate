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
    private let users: [User]
    
    init(viewModel: TodoBoardViewModel, users : [User]) {
        self._viewModel = State(initialValue: viewModel)
        self.users = users
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(users, id: \.uid) { user in
                UserTodoSection(
                    user: user,
                    isMe: viewModel.isMe(user),
                    addObserver: viewModel.addObserver,
                    removeObserver: viewModel.removeObserver
                )
            }
            
            if users.isEmpty {
                placeholder
            }
            
            Spacer(minLength: 50)
        }
        .task {
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

#Preview {
    OverlayContainer {
        
        ScrollView {
            VStack{
                TodoBoardView(viewModel: .init(container: DIContainer.stub, userInfo: AuthenticatedUser.stub),
                              users: User.stub)
                Spacer()
            }
        }
        .environment(DIContainer.stub)
        .frame(width: 400, height: 600)
    }
}
