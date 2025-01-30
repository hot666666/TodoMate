//
//  ExpandableView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct ExpandableView<Title: View, Content: View>: View {
    @AppStorage private var isExpanded: Bool
    let title: () -> Title
    let content: () -> Content
    
    init(isExpanded: Bool = true,
         storageKey: String,
         @ViewBuilder title: @escaping () -> Title,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
        self._isExpanded = AppStorage(wrappedValue: isExpanded, storageKey)
    }
    
    var body: some View {
        VStack {
            Button(action: {
                isExpanded.toggle()
            }, label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 20)
                    title()
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
