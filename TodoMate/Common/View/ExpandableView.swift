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
        VStack(spacing: 15) {
            HStack(alignment: .center, spacing: 5) {
                expandableButton
                header()
            }
            .font(.title)
            
            if isExpanded {
                content()
                    .padding(.leading, 5)
            }
        }
    }
    
    @ViewBuilder
    private var expandableButton: some View {
        Button(action: {
            isExpanded.toggle()
        }, label: {
            expandableImage
        })
        .hoverButtonStyle()
    }
    
    @ViewBuilder
    private var expandableImage: some View {
        if isExpanded {
            expanededImage
        } else {
            collapsedImage
        }
    }
    
    private let expanededImage: some View = Image(systemName: "chevron.down")
    private let collapsedImage: some View = Image(systemName: "chevron.down").rotationEffect(.degrees(-90))
}
