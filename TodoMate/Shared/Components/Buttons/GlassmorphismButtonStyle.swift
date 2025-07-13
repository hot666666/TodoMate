//
//  GlassmorphismButtonStyle.swift
//  Todo
//
//  Created by hs on 7/10/25.
//

import SwiftUI

struct GlassmorphismButtonStyle: ButtonStyle {
  let isSecondary: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .medium))
      .foregroundColor(isSecondary ? .secondary : .primary)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background {
        if isSecondary {
          RoundedRectangle(cornerRadius: 6)
            .fill(.ultraThinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
            )
        } else {
          RoundedRectangle(cornerRadius: 6)
            .fill(.thinMaterial)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
            )
        }
      }
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}
