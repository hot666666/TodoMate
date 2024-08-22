//
//  ExpandableView.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

struct ExpandableView<Content: View>: View {
    @State private var isExpanded: Bool
    let title: String
    let content: () -> Content
    
    init(title: String, isExpanded: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self._isExpanded = State(initialValue: isExpanded)
        self.title = title
        self.content = content
    }
    
    
    var body: some View {
        VStack {
            Button(action: {
                isExpanded.toggle()
            }, label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 20)
                    Text(" \(title)")
                    Spacer()
                }
                .font(.title3)
            })
            .hoverButtonStyle()
            
            if isExpanded {
                content()
            }
        }
    }
}
