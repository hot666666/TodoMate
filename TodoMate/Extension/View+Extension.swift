//
//  View+Extension.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

// TODO: - [Bug] content를 둘러싼 padding 부분에는 Color.balck.opacity(0.3)이 적용안됨
struct CustomSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var selectedItem: Item?
    let sheetContent: (Item) -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let item = selectedItem {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        selectedItem = nil
                    }
                
                GeometryReader { geometry in
                    sheetContent(item)
                        .frame(width: geometry.size.width * 0.6,
                               height: geometry.size.height * 0.7)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(10)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
}

extension View {
    func customSheet<Item: Identifiable, SheetContent: View>(
        selectedItem: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        self.modifier(CustomSheetModifier(selectedItem: selectedItem, sheetContent: content))
    }
}
