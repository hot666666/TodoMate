//
//  TintedCardStyle.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI

// MARK: - Tinted Card Modifier

/// 색상 배경과 테두리가 있는 카드 스타일 모디파이어
struct TintedCardModifier: ViewModifier {
  let color: Color
  var cornerRadius: CGFloat
  var backgroundOpacity: CGFloat
  var borderOpacity: CGFloat
  var borderWidth: CGFloat

  init(
    color: Color,
    cornerRadius: CGFloat = 4,
    backgroundOpacity: CGFloat = 0.1,
    borderOpacity: CGFloat = 0.3,
    borderWidth: CGFloat = 0.5,
  ) {
    self.color = color
    self.cornerRadius = cornerRadius
    self.backgroundOpacity = backgroundOpacity
    self.borderOpacity = borderOpacity
    self.borderWidth = borderWidth
  }

  func body(content: Content) -> some View {
    content
      .background(color.opacity(backgroundOpacity))
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(color.opacity(borderOpacity), lineWidth: borderWidth),
      )
  }
}

// MARK: - View Extensions

extension View {
  /// 색상 배경과 테두리가 있는 카드 스타일을 적용합니다.
  /// - Parameters:
  ///   - color: 기본 색상
  ///   - cornerRadius: 모서리 반경 (기본값: 4)
  ///   - backgroundOpacity: 배경 불투명도 (기본값: 0.1)
  ///   - borderOpacity: 테두리 불투명도 (기본값: 0.3)
  ///   - borderWidth: 테두리 두께 (기본값: 0.5)
  func tintedCard(
    color: Color,
    cornerRadius: CGFloat = 4,
    backgroundOpacity: CGFloat = 0.1,
    borderOpacity: CGFloat = 0.3,
    borderWidth: CGFloat = 0.5,
  ) -> some View {
    modifier(TintedCardModifier(
      color: color,
      cornerRadius: cornerRadius,
      backgroundOpacity: backgroundOpacity,
      borderOpacity: borderOpacity,
      borderWidth: borderWidth,
    ))
  }
}

#Preview {
  VStack {
    Text("Tinted Card")
      .padding()
      .tintedCard(color: .blue)

    Text("Custom Tinted Card")
      .padding()
      .tintedCard(
        color: .red,
        cornerRadius: 8,
        backgroundOpacity: 0.2,
        borderOpacity: 0.5,
        borderWidth: 1,
      )
  }
  .padding()
}
