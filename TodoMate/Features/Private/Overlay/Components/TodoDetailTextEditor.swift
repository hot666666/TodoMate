//
//  TodoDetailTextEditor.swift
//  Todo
//
//  Created by hs on 6/29/25.
//

import SwiftUI
import SwiftUIIntrospect

struct TodoDetailTextEditor: View {
  @State private var cleared = false
  @Binding var detail: String
  let onSubmit: () -> Void

  var body: some View {
    TextEditor(text: $detail)
      .offset(x: -3, y: 3)
      .scrollContentBackground(.hidden)
      .opacity(cleared ? 1 : 0)
      .overlay(alignment: .topLeading) {
        if detail.isEmpty {
          Text("메모")
            .offset(x: 2)
            .bold()
            .foregroundColor(.secondary)
            .allowsHitTesting(false)
        }
      }
      .frame(
        minHeight: DesignSystem.TodoSheet.TextEditor.minHeight,
        maxHeight: DesignSystem.TodoSheet.TextEditor.maxHeight, alignment: .top,
      )
      .fixedSize(horizontal: false, vertical: true)
      .introspect(.textEditor, on: .macOS(.v26)) { textView in
        textView.drawsBackground = false
        if let scrollView = textView.enclosingScrollView {
          scrollView.drawsBackground = false
          scrollView.contentView.drawsBackground = false
          scrollView.scrollerStyle = .overlay
          scrollView.autohidesScrollers = true
        }
        // Reveal after styles applied to avoid first-frame flash
        DispatchQueue.main.async { cleared = true }
      }
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
