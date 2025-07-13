//
//  TodoDetailTextEditor.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI

struct TodoDetailTextEditor: View {
  @Binding var detail: String
  let onSubmit: () -> Void

  var body: some View {
    TextEditor(text: $detail)
      .offset(x: -3, y: 3)
      .overlay(alignment: .topLeading) {
        if detail.isEmpty {
          Text("메모")
            .offset(x: 2)
            .bold()
            .foregroundColor(.secondary)
            .allowsHitTesting(false)
        }
      }
      .scrollContentBackground(.hidden)
      .frame(minHeight: TodoSheetDesignSystem.Component.TextEditor.minHeight, maxHeight: TodoSheetDesignSystem.Component.TextEditor.maxHeight, alignment: .top)
      .fixedSize(horizontal: false, vertical: true)
      // Command + Enter to submit
      .onKeyPress(.return, phases: .down) { key in
        if key.modifiers.contains(.command) {
          onSubmit()
          return .handled
        }
        return .ignored
      }
  }
}
