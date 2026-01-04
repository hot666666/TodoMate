//
//  CardStyle.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

// MARK: - Card Container Modifier

struct CardContainerModifier: ViewModifier {
  var cornerRadius: CGFloat
  var material: Material
  var shadowRadius: CGFloat
  var shadowY: CGFloat

  init(
    cornerRadius: CGFloat = 16,
    material: Material = .ultraThin,
    shadowRadius: CGFloat = 10,
    shadowY: CGFloat = 4,
  ) {
    self.cornerRadius = cornerRadius
    self.material = material
    self.shadowRadius = shadowRadius
    self.shadowY = shadowY
  }

  func body(content: Content) -> some View {
    content
      .background(material)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white.opacity(0.3), lineWidth: 1),
      )
      .shadow(color: .black.opacity(0.05), radius: shadowRadius, x: 0, y: shadowY)
  }
}

extension View {
  func cardContainer(
    cornerRadius: CGFloat = 16,
    material: Material = .ultraThin,
    shadowRadius: CGFloat = 10,
    shadowY: CGFloat = 4,
  ) -> some View {
    modifier(
      CardContainerModifier(
        cornerRadius: cornerRadius,
        material: material,
        shadowRadius: shadowRadius,
        shadowY: shadowY,
      ),
    )
  }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
  var padding: EdgeInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
  var cornerRadius: CGFloat = 8

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(padding)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(Color.white.opacity(0.3), lineWidth: 1),
      )
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == CardButtonStyle {
  static var card: CardButtonStyle {
    CardButtonStyle()
  }

  static func card(padding: EdgeInsets) -> CardButtonStyle {
    CardButtonStyle(padding: padding)
  }
}
