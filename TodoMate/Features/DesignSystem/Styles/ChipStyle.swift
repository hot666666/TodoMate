//
//  ChipStyle.swift
//  TodoMate
//
//  Created by hs on 11/14/24.
//

import SwiftUI

// MARK: - Chip Background

/// Capsule 형태의 배경 (태그, 칩 등에 사용)
struct ChipBackground: View {
  var isActive: Bool = false
  var color: Color = .primary

  var body: some View {
    Capsule()
      .fill(fillColor)
      .overlay(
        Capsule()
          .strokeBorder(strokeColor, lineWidth: isActive ? 1 : 0.5),
      )
  }

  private var fillColor: Color {
    isActive ? color.opacity(0.1) : .primary.opacity(0.06)
  }

  private var strokeColor: Color {
    isActive ? color.opacity(0.5) : .white.opacity(0.1)
  }
}

// MARK: - Chip Style Modifier

/// 칩/태그 스타일 모디파이어
struct ChipStyle: ViewModifier {
  var isActive: Bool = false
  var color: Color = .primary
  var isExpanded: Bool = false

  func body(content: Content) -> some View {
    content
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(isActive ? color : .secondary)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .frame(maxWidth: isExpanded ? .infinity : nil, alignment: .leading)
      .background(ChipBackground(isActive: isActive, color: color))
      .contentShape(Capsule())
  }
}

extension View {
  func chipStyle(isActive: Bool = false, color: Color = .primary, isExpanded: Bool = false) -> some View {
    modifier(ChipStyle(isActive: isActive, color: color, isExpanded: isExpanded))
  }
}
