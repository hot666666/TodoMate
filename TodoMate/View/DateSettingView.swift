//
//  DateSettingView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//


import SwiftUI

struct DateSettingView: View {
    var todo: TodoItem
    
    var body: some View {
        VStack {
            CalendarView(todoDate: Bindable(todo).date)
        }
        .padding()
        .frame(width: Const.DateSettingViewFrame.WIDTH, height: Const.DateSettingViewFrame.HEIGHT)
        .background(.ultraThickMaterial)
        .cornerRadius(10)
    }
}

#Preview {
    DateSettingView(todo: .stub)
}
