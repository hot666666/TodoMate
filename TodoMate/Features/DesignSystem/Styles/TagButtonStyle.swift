//
//  TagButtonStyle.swift
//  TodoMate
//
//  Created by hs on 11/14/24.
//

import SwiftUI

struct TagButtonStyle: ViewModifier {
  var isActive: Bool = false
  var activeColor: Color = .white
  var isExpanded: Bool = false

  func body(content: Content) -> some View {
    content
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(isActive ? activeColor : .secondary)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .frame(maxWidth: isExpanded ? .infinity : nil, alignment: .leading)
      .background {
        if isActive {
          Capsule()
            .fill(activeColor.opacity(0.1))
            .overlay(
              Capsule()
                .strokeBorder(activeColor.opacity(0.5), lineWidth: 1),
            )
        } else {
          Capsule()
            .fill(.primary.opacity(0.06))
            .overlay(
              Capsule()
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5),
            )
        }
      }
      .contentShape(Capsule())
  }
}

extension View {
  func tagButtonStyle(
    isActive: Bool = false, activeColor: Color = .white, isExpanded: Bool = false,
  ) -> some View {
    modifier(
      TagButtonStyle(isActive: isActive, activeColor: activeColor, isExpanded: isExpanded))
  }
}
