//
//  CardStyle.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
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

// MARK: - Custom Rounded Rectangle (for chat bubbles)

struct CustomRoundedRectangle: Shape {
  var topLeft: CGFloat
  var topRight: CGFloat
  var bottomLeft: CGFloat
  var bottomRight: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.size.width
    let height = rect.size.height

    // Top left
    path.move(to: CGPoint(x: topLeft, y: 0))

    // Top right
    path.addLine(to: CGPoint(x: width - topRight, y: 0))
    path.addArc(
      center: CGPoint(x: width - topRight, y: topRight), radius: topRight,
      startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false,
    )

    // Bottom right
    path.addLine(to: CGPoint(x: width, y: height - bottomRight))
    path.addArc(
      center: CGPoint(x: width - bottomRight, y: height - bottomRight), radius: bottomRight,
      startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false,
    )

    // Bottom left
    path.addLine(to: CGPoint(x: bottomLeft, y: height))
    path.addArc(
      center: CGPoint(x: bottomLeft, y: height - bottomLeft), radius: bottomLeft,
      startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false,
    )

    // Top left
    path.addLine(to: CGPoint(x: 0, y: topLeft))
    path.addArc(
      center: CGPoint(x: topLeft, y: topLeft), radius: topLeft,
      startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false,
    )

    return path
  }
}

extension View {
  func corners(topLeft: CGFloat, topRight: CGFloat, bottomLeft: CGFloat, bottomRight: CGFloat)
    -> some Shape {
    CustomRoundedRectangle(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    )
  }
}
