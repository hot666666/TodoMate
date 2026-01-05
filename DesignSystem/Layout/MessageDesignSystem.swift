//
//  MessageDesignSystem.swift
//  Todo
//
//  Created by hs on 7/10/25.
//

import SwiftUI

enum MessageDesignSystem {
  // MARK: - Layout Constants

  enum Layout {
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 12
  }

  // MARK: - Design Tokens

  enum CornerRadius {
    static let large: CGFloat = 12
    static let medium: CGFloat = 10
    static let small: CGFloat = 6
  }

  enum Padding {
    static let large: CGFloat = 16
    static let medium: CGFloat = 12
    static let small: CGFloat = 8
    static let xSmall: CGFloat = 6
  }

  enum Spacing {
    static let medium: CGFloat = 12
    static let small: CGFloat = 8
    static let xSmall: CGFloat = 5
  }

  enum Shadow {
    static let light: CGFloat = 1
  }

  // MARK: - Component-specific Constants

  enum Component {
    enum MessageList {
      static let itemPadding: CGFloat = 10
      static let editingMaxHeight: CGFloat = 120
      static let editingMinHeight: CGFloat = 40
    }

    enum MessageInput {
      static let minHeight: CGFloat = 30
      static let maxHeight: CGFloat = 200
      static let buttonSize: CGFloat = 24
      static let plusButtonSize: CGFloat = 18
      static let containerHeight: CGFloat = 38
      static let containerPadding: CGFloat = 16
    }

    enum Typography {
      static let contentFont: Font = .system(size: 13)
      static let captionFont: Font = .caption
      static let bodyFont: Font = .body
    }
  }
}
