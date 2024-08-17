//
//  TodoListHeader.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

struct TodoListHeader<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
            Spacer()
            content()
        }
        .bold()
        .padding([.top, .horizontal], 5)
        
        Divider()
    }
}
