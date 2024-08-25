//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/25/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(DIContainer.self) private var container: DIContainer
    @Environment(AppState.self) private var appState: AppState
    @State private var userManager: StubUserManager = .init()
    @State private var chatManager: StubChatManager = .init()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(userManager.users) { user in
                    ExpandableView(title: user.name, isExpanded: true) {
                        todoBox(userId: user.fid)
                            .padding(.horizontal, 30)
                    }
                }
                .padding(.top, 5)
            }
            .disabled(appState.isSelectedTodo)
        }
        .task {
            await userManager.fetch()
        }
        .customSheet(selectedItem: appState.selectedTodo) {
            TodoListSheetView(todo: $0)
        }
    }
    
    @ViewBuilder
    private func todoBox(userId: String) -> some View {
        TodoBox(viewModel: .init(container: container, userId: userId))
    }
}

#Preview {
    @Previewable @State var container: DIContainer = .stub
    @Previewable @State var appState: AppState = .init()
    
    
    ContentView()
        .environment(container)
        .environment(appState)
        .frame(width: 500, height: 500)
}
