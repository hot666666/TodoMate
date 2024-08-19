//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var userManager: UserManager = .init()
    @State private var todoManager: TodoManager = .init()
    @State private var chatManager: ChatManager = .init()
    
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // TODO: - 최하단 채팅으로 스크롤 이동
                ExpandableView(title: "채팅\(chatManager.formatCount)", isExpanded: false) {
                    ChatListView()
                        .padding(.horizontal, 5)
                        .environment(chatManager)
                }
                
                ForEach(userManager.users) { user in
                    ExpandableView(title: user.name) {
                        TodoListView(userId: user.fid)
                            .padding()
                            .frame(height: max(50, geometry.size.height / 2 - 100))
                    }
                }
                .padding(.top, 5)
            }
            .padding(5)
        }
        .task {
            await userManager.fetch()
        }
        .customSheet(selectedItem: appState.selectedTodo) {
            TodoListSheetView(todo: $0)
        }
        .customOverlayView(isPresented: appState.popover, overlayPosition: appState.popoverPosition) {
            DateSettingView()
        }
        .environment(todoManager)
    }
}


#Preview  {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
        .environment(AppState())
}
