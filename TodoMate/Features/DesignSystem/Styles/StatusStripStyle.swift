//
//  StatusStripStyle.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI

// MARK: - Status Strip Modifier

/// 뷰의 왼쪽에 상태 색상 띠(Strip)를 추가하는 구조적 모디파이어
struct StatusStripModifier: ViewModifier {
  let color: Color
  var width: CGFloat = 5

  func body(content: Content) -> some View {
    HStack(spacing: 0) {
      Rectangle()
        .fill(color)
        .frame(width: width)
      content
    }
  }
}

// MARK: - View Extensions

extension View {
  /// 뷰의 왼쪽에 상태 색상 띠를 추가합니다.
  /// - Parameters:
  ///   - color: 띠의 색상
  ///   - width: 띠의 너비 (기본값: 5)
  func statusStrip(color: Color, width: CGFloat = 5) -> some View {
    modifier(StatusStripModifier(color: color, width: width))
  }
}

#Preview {
  Text("Hello World")
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .statusStrip(color: .blue)
    .materialCard()
    .padding()
}
