//
//  DateSettingView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//


import SwiftUI

struct DateSettingView: View {
    @Environment(AppState.self) private var appState: AppState
    
    var body: some View {
        VStack {
            if let todo = appState.selectedTodo {
                CalendarView(todoDate: Bindable(todo).date)
            } else {
                EmptyView()
            }
        }
        .padding()
        .frame(width: Const.DateSettingViewFrame.WIDTH, height: Const.DateSettingViewFrame.HEIGHT)
        .background(.ultraThickMaterial)
        .cornerRadius(10)
    }
}

#Preview {
    @Previewable @State var appState: AppState = .init()
    
    DateSettingView()
        .environment(appState)
}
