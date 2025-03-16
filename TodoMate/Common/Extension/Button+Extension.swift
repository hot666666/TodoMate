//
//  Button+Extension.swift
//  TodoMate
//
//  Created by hs on 8/16/24.
//

import SwiftUI

struct HoverButtonStyle: ButtonStyle {
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.secondary)
      .padding(5)
      .background(isHovering ? Color.gray.opacity(0.2) : Color.clear)
      .cornerRadius(5)
      .onHover { isHovering = $0 }
  }
}

struct HoverButtonStyle2: ButtonStyle {
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.secondary)
      .background(isHovering ? Color.gray.opacity(0.2) : Color.clear)
      .cornerRadius(5)
      .onHover { isHovering = $0 }
  }
}

struct HoverButtonStyle3: ButtonStyle {
  @State private var isHovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.secondary)
      .padding(5)
      .background(Color.gray.opacity(0.2))
      .cornerRadius(5)
      .opacity(isHovering ? 1 : 0)
      .onHover { isHovering = $0 }
  }
}

extension Button {
  func hoverButtonStyle() -> some View {
    buttonStyle(HoverButtonStyle())
  }

  func hoverButtonStyle2() -> some View {
    buttonStyle(HoverButtonStyle2())
  }

  func hoverButtonStyle3() -> some View {
    buttonStyle(HoverButtonStyle3())
  }
}
