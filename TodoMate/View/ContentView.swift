//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState: AppState
    @State var userManager: UserManager = UserManager()
    @State var todoManager: TodoManager = TodoManager()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ForEach(userManager.users) { user in
                    if let userId = user.fid {
                        TodoListView(userId: userId)
                            .padding()
                            .frame(height: geometry.size.height / 2 - 10)
                    }
                }
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
        .environment(todoManager)
    }
}


#Preview  {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
        .environment(AppState())
}
