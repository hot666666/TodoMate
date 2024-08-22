//
//  TodoListView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

// MARK: - TodoListView
struct TodoListView: View {
    @State var viewModel: TodoListViewModel
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                TodoListHeader(title: "오늘의 투두") {
                    AddTodoButton(action: viewModel.create)
                }
                TodoListContent()
                    .environment(viewModel)
            }
        }
        .contextMenu {
            AddTodoButton(isContextMenu: true, action: viewModel.create)
        }
        .task {
            await viewModel.fetch()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - AddTodoButton
fileprivate struct AddTodoButton: View {
    var isContextMenu: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(Image(systemName: "plus"))+Text(isContextMenu ? " Todo 추가" : "")
        }
        .hoverButtonStyle()
    }
}
