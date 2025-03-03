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
                ExpandableView(
                    storageKey: user.uid,
                    header: { header(for: user) },
                    content: { content(for: user) }
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
    private func header(for user: User) -> some View {
        HStack {
            Text(user.nickname)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func content(for user: User) -> some View {
        TodoBoxView(
            user: user,
            isMine: viewModel.isMe(user),
            todos: viewModel.todosBinding(for: user),
            createTodo: viewModel.createTodo,
            deleteTodo: viewModel.deleteTodo,
            updateTodo: viewModel.updateTodo
        )
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


#Preview {
    OverlayContainer {
        ScrollView {
            VStack{
                TodoBoardView(viewModel: .init(container: .stub, userInfo: .stub),
                              users: User.stub)
                Spacer()
            }
        }
        .environment(DIContainer.stub)
        .frame(width: 400, height: 600)
        .padding()
    }
}
