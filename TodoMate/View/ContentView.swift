//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(DIContainer.self) private var container: DIContainer
    @Environment(AppState.self) private var appState: AppState
    @State private var userManager: UserManager = .init()
    @State private var chatManager: ChatManager = .init()
    
    var body: some View {
            ScrollView {
                VStack {
                    ExpandableView(title: "채팅\(chatManager.formatCount)", storageKey: "chatlist") {
                        ChatListView()
                            .padding(.horizontal, 5)
                            .environment(chatManager)
                    }
                    .task {
                        await chatManager.onAppear()
                    }
                    .padding(.top)
                    
                    ForEach(userManager.users) { user in
                        ExpandableView(title: user.name, storageKey: "user_\(user.fid)") {
                            ExpandableView(title: "캘린더", storageKey: "calendar_\(user.fid)") {
                                TodosInMonthView(viewModel: .init(container: container, userId: user.fid))
                            }
                            .padding(.horizontal, 30)
                            
                            todoBox(userId: user.fid)
                                .padding(.horizontal, 30)
                        }
                    }
                    .padding(.top, 5)
                }
                .disabled(appState.isSelectedTodo)
                
                Spacer()
                    .frame(height: 50)
            }
        .task {
            await userManager.fetch()
        }
        .customSheet(selectedItem: appState.selectedTodo) {
            TodoSheet(todo: $0)
        }
        .customOverlayView(isPresented: appState.popover, overlayPosition: appState.popoverPosition) {
            DateSettingView()
        }
    }
    
    @ViewBuilder
    private func todoBox(userId: String) -> some View {
        TodoBox(viewModel: .init(container: container, userId: userId))
    }
}


#Preview  {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
        .environment(AppState())
}
