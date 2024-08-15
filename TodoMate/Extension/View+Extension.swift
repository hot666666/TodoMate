//
//  View+Extension.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

// CustomSheetModifier 정의
struct CustomSheetModifier<Item: Identifiable, SheetContent: View, OnDismiss>: ViewModifier {  // TODO: - Generic 공부
    @Environment(AppState.self) private var appState: AppState
    let sheetContent: (Item, OnDismiss) -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let item = appState.selectedTodo as? Item,
               let onDismiss = appState.selectedTodoUpdate as? OnDismiss {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.selectedTodo = nil
                        appState.selectedTodoUpdate = nil
                    }
                
                /// 지정된 크기로 sheetContent 표시
                GeometryReader { geometry in
                    sheetContent(item, onDismiss)
                        .frame(width: geometry.size.width * 0.6,
                               height: geometry.size.height * 0.7)
                        .background(.regularMaterial)
                        .cornerRadius(10)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
}

extension View {
    func customSheet<Item: Identifiable, SheetContent: View, OnDismiss>(
        selectedItem: Item?,
        @ViewBuilder content: @escaping (Item, OnDismiss) -> SheetContent
    ) -> some View {
        self.modifier(CustomSheetModifier(sheetContent: content))
    }
}


// CustomOverlayModifier 정의
struct CustomOverlayModifier<OverlayContent: View>: ViewModifier {
    @Environment(AppState.self) private var appState: AppState
    let overlayContent: () -> OverlayContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if appState.popover  {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.popover = false
                    }
                
                /// 지정된 위치에 overlayContent 표시
                overlayContent()
                    .position(appState.popoverPosition)
            }
        }
    }
}

extension View {
    func customOverlayView<OverlayContent: View>(
        isPresented: Bool,
        overlayPosition: CGPoint,
        @ViewBuilder overlayContent: @escaping () -> OverlayContent
    ) -> some View {
        self.modifier(CustomOverlayModifier(overlayContent: overlayContent))
    }
}
