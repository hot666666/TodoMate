//
//  TodoList.swift
//  TodoMate
//
//  Created by hs on 8/25/24.
//

import SwiftUI

struct TodoBox: View {
    @State var viewModel: TodoBoxViewModel
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                todoList
                addButton
            }
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
    
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
        }
        .bold()
        .padding(5)
        
        Divider()
    }
    
    @ViewBuilder
    private var todoList: some View {
        TodoList(viewModel: viewModel)
            .padding([.top, .trailing], 5)
            .padding(.leading)
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: viewModel.create) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 20)
        .padding(.bottom, 5)
    }
}

struct TodoList: View {
    @Environment(AppState.self) private var appState: AppState
    @Bindable var viewModel: TodoBoxViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(viewModel.todos) { todo in
                TodoListItem(todo: todo)
                    .onHover { viewModel.setHoveringTodo($0 ? todo.id : nil) }
                    .onTapGesture {
                        appState.updateSelectTodo(todo)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary)
                            .opacity(viewModel.isHovering(todo) ? 0.2 : 0)
                    )
                    .contextMenu {
                        Button(action: {
                            viewModel.remove(todo)
                        }) {
                            Text(Image(systemName: "trash"))+Text(" 삭제")
                        }
                    }
                
            }
        }
    }
}

struct TodoListItem: View {
    var todo: Todo
    
    var body: some View {
        HStack {
            status
            content
            Spacer()
            detail
        }
    }
    
    @ViewBuilder
    private var status: some View {
        StatusButton(todo: todo)
    }
    
    @ViewBuilder
    private var content: some View {
        Text(todo.content.isEmpty ? "이름없음" : todo.content)
            .font(.title3)
    }
    
    @ViewBuilder
    private var detail: some View {
        Text(todo.detail)
            .foregroundColor(.secondary)
            .font(.footnote)
            .lineLimit(1)
            .underline()
            .padding(.trailing, 5)
    }
}

#Preview("TodoBox") {
    TodoBox(viewModel: .init(container: .stub, userId: "user_id1"))
        .frame(width: 500, height: 800)
        .padding(20)
        .environment(AppState())
}
