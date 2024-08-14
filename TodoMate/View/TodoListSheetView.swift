//
//  TodoListSheetView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

// TODO: - CustomSheetModifier에서 또 sheet 처리해야 안잘림, 해당 뷰 외부 터치 시 DateSettingView만 꺼지도록 설정해야함
struct TodoListSheetView: View {
    @State private var showOverlay = false
    @State private var buttonFrame: CGRect = .zero
    
    var todo: TodoItem
    var onDismiss: (TodoItem) -> Void
    
    
    init(todo: TodoItem, onDismiss: @escaping (TodoItem) -> Void) {
        self.todo = todo
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 15) {
                todoItemContent
                
                /// toggle showOverlay
                todoItemDate
                
                todoItemStatus
                
                todoItemDetail
                
                Spacer()
            }
            .font(.title3)
            .padding(60)
            .onDisappear {
                onDismiss(todo)
            }
            
            // Overlay View
            if showOverlay {
                Color.black.opacity(0.01)
                    .onTapGesture {
                        showOverlay = false
                    }
                GeometryReader { geometry in
                    DateSettingView(todo: todo)
                    /// CustomSheetModifier - Width: geometry.size.width * 0.6, Height: geometry.size.height * 0.7
                        .position(x: buttonFrame.minX + Const.DateSettingViewFrame.WIDTH/2 - geometry.size.width * 0.333,
                                  y: buttonFrame.minY + Const.DateSettingViewFrame.HEIGHT/2 - geometry.size.height * 0.214)
                }
            }
        }
        .zIndex(1)
    }
}

extension TodoListSheetView {
    private var todoItemContent: some View {
        TextField("이름없음", text: Bindable(todo).content)
            .textFieldStyle(.plain)
            .font(.system(size: 40))
            .bold()
    }
    
    private var todoItemDate: some View {
        HStack(spacing: 15) {
            Text(Image(systemName: "calendar")) + Text(" 날짜")
            
            Button(action: {
                self.showOverlay.toggle()
            }) {
                Text(todo.date.toYYYYMMDDString())
            }
            /// Button 위치를 얻기위한 과정
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: ButtonFramePreferenceKey.self, value: geometry.frame(in: .global))
            })
            .onPreferenceChange(ButtonFramePreferenceKey.self) { value in
                self.buttonFrame = value
            }
        }
    }
    
    private var todoItemStatus: some View {
        HStack(spacing: 15) {
            Text(Image(systemName: "circle.dotted")).bold() + Text(" 상태")
            StatusPopoverButton(todo: todo)
                .padding(.leading, 5)
        }
    }
    
    private var todoItemDetail: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(Image(systemName: "note.text")).bold() + Text(" 메모")
            TextEditor(text: Bindable(todo).detail)
                .frame(maxHeight: .infinity)
        }
    }
}

#Preview("SheetView") {
    TodoListSheetView(todo: .stub) { _ in
        
    }
    .frame(width: 500, height: 700)
}

// TODO: - 공부
struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
