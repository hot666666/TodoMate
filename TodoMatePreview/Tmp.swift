//
//  Tmp.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import SwiftUI

fileprivate struct CalendarDayTodoView: View {
    var todo: Todo
    
    var body: some View {
        HStack {
            Text(todo.content.isEmpty ? "이름없음" : todo.content.truncated())
                .padding(3)
                .foregroundColor(.customGrayFg)
            Spacer()
        }
        .background(Color.customGrayBg, in: RoundedRectangle(cornerRadius: 3))
    }
}

#Preview {
    VStack {
        CalendarDayTodoView(todo: .init())
        Button(action: {
            
        }) {
            CalendarDayTodoView(todo: .init())
        }
        .background(Color.customGrayBg)
        
    }
    .padding(50)
    .frame(width: 300, height: 300)
}
