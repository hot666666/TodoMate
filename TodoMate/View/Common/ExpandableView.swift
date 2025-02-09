//
//  ExpandableView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct ExpandableView<Header: View, Content: View>: View {
    @AppStorage private var isExpanded: Bool
    let header: () -> Header
    let content: () -> Content
    
    init(isExpanded: Bool = true,
         storageKey: String,
         @ViewBuilder header: @escaping () -> Header,
         @ViewBuilder content: @escaping () -> Content) {
        self.header = header
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
                    header()
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
