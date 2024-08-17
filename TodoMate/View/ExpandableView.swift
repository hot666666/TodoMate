//
//  ExpandableView.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

struct ExpandableView<Content: View>: View {
    @State private var isExpanded = true
    let title: String
    let content: () -> Content
    
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
