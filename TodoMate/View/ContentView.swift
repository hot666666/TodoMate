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
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    ExpandableView(title: "채팅\(chatManager.formatCount)") {
                        ChatListView()
                            .padding(.horizontal, 5)
                            .environment(chatManager)
                    }
                    .task {
                        await chatManager.onAppear()
                    }
                    .padding(.top)
                    
                    ForEach(userManager.users) { user in
                        ExpandableView(title: user.name, isExpanded: true) {
                            ExpandableView(title: "캘린더") {
                                TodosInMonthView(viewModel: .init(container: container, userId: user.fid))
                            }
                            .padding(.horizontal)
                            
                            TodoListView(viewModel: .init(container: container, userId: user.fid))
                                .padding()
                                .frame(height: max(50, geometry.size.height / 2 - 150))
                        }
                    }
                    .padding(.top, 5)
                }
                .disabled(appState.isSelectedTodo)
                .padding(.horizontal, max(10, geometry.size.width * 0.1))
            }
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
    }
}


#Preview  {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
        .environment(AppState())
}
