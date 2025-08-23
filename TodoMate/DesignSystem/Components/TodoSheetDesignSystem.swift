//
//  TodoSheetDesignSystem.swift
//  Todo
//
//  Created by hs on 7/10/25.
//

import SwiftUI

enum TodoSheetDesignSystem {
  // MARK: - Layout Constants

  enum Layout {
    static let sheetPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 16
    static let componentSpacing: CGFloat = 12
    static let maxWidth: CGFloat = 552
  }

  // MARK: - Design Tokens

  enum CornerRadius {
    static let medium: CGFloat = 8
    static let small: CGFloat = 6
  }

  enum Padding {
    static let medium: CGFloat = 12
    static let small: CGFloat = 8
    static let xSmall: CGFloat = 4
  }

  enum Spacing {
    static let medium: CGFloat = 12
    static let small: CGFloat = 8
  }

  // MARK: - Component-specific Constants

  enum Component {
    enum DatePicker {
      static let width: CGFloat = 250
      static let height: CGFloat = 300
      static let padding: CGFloat = 16
    }

    enum StatusPicker {
      static let buttonPadding: CGFloat = 8
      static let popoverPadding: CGFloat = 12
      static let height: CGFloat = 100
      static let width: CGFloat = 90
    }

    enum TextField {
      static let minHeight: CGFloat = 40
      static let padding: CGFloat = 12
    }

    enum TextEditor {
      static let minHeight: CGFloat = 20
      static let maxHeight: CGFloat = 100
      static let padding: CGFloat = 12
    }

    enum Typography {
      static let titleFont: Font = .title
      static let bodyFont: Font = .body
      static let captionFont: Font = .caption
    }
  }
}
