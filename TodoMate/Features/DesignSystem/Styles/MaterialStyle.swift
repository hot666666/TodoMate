//
//  MaterialStyle.swift
//  TodoMate
//
//  Created by agent on 1/21/26.
//

import SwiftUI

// MARK: - Material Style Shape

/// 머티리얼 스타일에 사용할 도형 유형
enum MaterialShape {
  case roundedRect(cornerRadius: CGFloat)
  case capsule

  @ViewBuilder
  func clipShape(_ view: some View) -> some View {
    switch self {
    case let .roundedRect(cornerRadius):
      view.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    case .capsule:
      view.clipShape(Capsule())
    }
  }

  @ViewBuilder
  func strokeBorder(color: Color, lineWidth: CGFloat) -> some View {
    switch self {
    case let .roundedRect(cornerRadius):
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(color, lineWidth: lineWidth)
    case .capsule:
      Capsule()
        .stroke(color, lineWidth: lineWidth)
    }
  }
}

// MARK: - Material Style Modifier

/// 통합 머티리얼 스타일 모디파이어
struct MaterialStyleModifier: ViewModifier {
  var material: Material
  var shape: MaterialShape
  var border: Color?
  var borderWidth: CGFloat
  var shadowColor: Color
  var shadowRadius: CGFloat
  var shadowY: CGFloat

  init(
    material: Material = .regularMaterial,
    shape: MaterialShape = .roundedRect(cornerRadius: 12),
    border: Color? = nil,
    borderWidth: CGFloat = 1.0,
    shadowColor: Color = .black.opacity(0.05),
    shadowRadius: CGFloat = 2,
    shadowY: CGFloat = 1,
  ) {
    self.material = material
    self.shape = shape
    self.border = border
    self.borderWidth = borderWidth
    self.shadowColor = shadowColor
    self.shadowRadius = shadowRadius
    self.shadowY = shadowY
  }

  func body(content: Content) -> some View {
    shape.clipShape(
      content
        .background(material),
    )
    .overlay {
      if let border {
        shape.strokeBorder(color: border, lineWidth: borderWidth)
      }
    }
    .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
  }
}

// MARK: - View Extensions

extension View {
  /// 카드형 머티리얼 스타일
  func materialCard(cornerRadius: CGFloat = 16) -> some View {
    modifier(
      MaterialStyleModifier(
        shape: .roundedRect(cornerRadius: cornerRadius),
        shadowColor: .black.opacity(0.05),
        shadowRadius: 2,
        shadowY: 1,
      ))
  }

  /// 카드형 오버레이 머티리얼 스타일
  func materialCardOverlay(cornerRadius: CGFloat = 16, border: Bool = false) -> some View {
    modifier(
      MaterialStyleModifier(
        shape: .roundedRect(cornerRadius: cornerRadius),
        border: border ? .white.opacity(0.3) : nil,
        shadowColor: .black.opacity(0.2),
        shadowRadius: 10,
        shadowY: 0,
      ))
  }

  /// 캡슐형 머티리얼 스타일
  func materialCapsule() -> some View {
    modifier(
      MaterialStyleModifier(
        material: .ultraThinMaterial,
        shape: .capsule,
        shadowColor: .black.opacity(0.15),
        shadowRadius: 8,
        shadowY: 4,
      ))
  }

  /// 확인 팝업용 머티리얼 스타일
  func confirmationCard() -> some View {
    modifier(
      MaterialStyleModifier(
        material: .ultraThickMaterial,
        shape: .roundedRect(cornerRadius: DesignSystem.Confirmation.cornerRadius),
        border: .secondary.opacity(DesignSystem.Confirmation.strokeOpacity),
        borderWidth: DesignSystem.Confirmation.strokeWidth,
        shadowColor: .black.opacity(0.2),
        shadowRadius: DesignSystem.Confirmation.shadowRadius,
        shadowY: 0,
      ))
  }

  /// 오버레이용 머티리얼 스타일
  func materialCardOverlay(cornerRadius: CGFloat = 16) -> some View {
    background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
  }
}

// MARK: - Material Button Style

/// 머티리얼 스타일 버튼
struct MaterialButtonStyle: ButtonStyle {
  var padding: EdgeInsets = .init(top: 10, leading: 20, bottom: 10, trailing: 20)
  var cornerRadius: CGFloat = 8

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(padding)
      .modifier(
        MaterialStyleModifier(
          shape: .roundedRect(cornerRadius: cornerRadius),
          border: .white.opacity(0.3),
          shadowColor: .black.opacity(0.05),
          shadowRadius: 2,
          shadowY: 2,
        ),
      )
      .opacity(configuration.isPressed ? 0.8 : 1.0)
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == MaterialButtonStyle {
  static var material: MaterialButtonStyle { MaterialButtonStyle() }

  static func material(padding: EdgeInsets, cornerRadius: CGFloat = 8) -> MaterialButtonStyle {
    MaterialButtonStyle(padding: padding, cornerRadius: cornerRadius)
  }
}

#Preview("Material Styles") {
  VStack(spacing: 20) {
    Text("Material Card")
      .padding()
      .frame(width: 200)
      .materialCard()

    Text("Material Panel")
      .padding()
      .frame(width: 200)
      .materialCardOverlay(border: true)

    Text("Material Capsule")
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
      .materialCapsule()

    Button("Material Button") {}
      .buttonStyle(MaterialButtonStyle())
  }
  .padding(40)
  .background(Color.gray.opacity(0.3))
}
