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
    
    var body: some View {
        VStack{
            ForEach(userManager.users) { user in
                if let userId = user.fid {
                    TodoListView(todoManager: .init(userId: userId))
                        .padding()
                        
                }
            }
        }
        .task {
            await userManager.fetch()
        }
        /// MacOS 앱은 기본적으로 .sheet를 이용할 때, 외부 뷰 터치 시 dismiss가 수행을 안해서 따로 만든 커스텀 수정자
        .customSheet(selectedItem: appState.selectedTodo) { todo, update in
            TodoListSheetView(todo: todo, onDismiss: update)
        }
        /// AppState의 position에 지정된 위치에 뷰를 나타태는 커스텀 수정자
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
