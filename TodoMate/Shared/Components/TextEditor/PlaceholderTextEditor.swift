//
//  PlaceholderTextEditor.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import SwiftUI
import SwiftUIIntrospect

/// 플레이스홀더를 지원하는 TextEditor 컴포넌트
struct PlaceholderTextEditor: View {
  @Binding var text: String
  let placeholder: String
  let minHeight: CGFloat?
  let maxHeight: CGFloat?
  let offset: CGSize
  let onSubmit: (() -> Void)?

  @State private var cleared = false

  init(
    text: Binding<String>,
    placeholder: String,
    minHeight: CGFloat? = nil,
    maxHeight: CGFloat? = nil,
    offset: CGSize = CGSize(width: -3, height: 3),
    onSubmit: (() -> Void)? = nil
  ) {
    _text = text
    self.placeholder = placeholder
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.offset = offset
    self.onSubmit = onSubmit
  }

  var body: some View {
    TextEditor(text: $text)
      .offset(x: offset.width, y: offset.height)
      .scrollContentBackground(.hidden)
      .opacity(cleared ? 1 : 0)
      .overlay(alignment: .topLeading) {
        if text.isEmpty {
          Text(placeholder)
            .offset(x: 2)
            .foregroundColor(.secondary)
            .allowsHitTesting(false)
        }
      }
      .if(minHeight != nil || maxHeight != nil) { view in
        view.frame(
          minHeight: minHeight,
          maxHeight: maxHeight,
          alignment: .top
        )
        .fixedSize(horizontal: false, vertical: true)
      }
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
      .if(onSubmit != nil) { view in
        view.onKeyPress(.return, phases: .down) { key in
          if key.modifiers.contains(.command), let onSubmit {
            onSubmit()
            return .handled
          }
          return .ignored
        }
      }
  }
}

// MARK: - Conditional View Modifier

extension View {
  /// 조건부로 modifier를 적용합니다.
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    PlaceholderTextEditor(
      text: .constant(""),
      placeholder: "메모를 입력하세요",
      minHeight: 100,
      maxHeight: 200
    )
    .padding()
    .background(.gray.opacity(0.1))

    PlaceholderTextEditor(
      text: .constant("Some text"),
      placeholder: "메모를 입력하세요",
      minHeight: 100,
      maxHeight: 200
    )
    .padding()
    .background(.gray.opacity(0.1))
  }
  .padding()
  .frame(width: 400)
}
