//
//  HomeDesignSystem.swift
//  Todo
//
//  Created by hs on 7/9/25.
//

import SwiftUI

enum HomeDesignSystem {
  // MARK: - Global Layout Constants

  enum Layout {
    static let containerPadding: CGFloat = 10 // Common padding (pickerPadding)
    static let sectionSpacing: CGFloat = 10 // HomeScreen VStack spacing
    static let safeAreaInset: CGFloat = 4 // TodoList top inset
  }

  // MARK: - Design Tokens

  enum CornerRadius {
    static let large: CGFloat = 12 // HomeScreen sections, UserPickerButton
    static let medium: CGFloat = 8 // TodoItem, EditableMarkdownView overlay
    static let small: CGFloat = 6 // UserPickerButton segments, EditableMarkdownView button
  }

  enum Padding {
    static let large: CGFloat = 16 // TodoItem horizontal
    static let medium: CGFloat = 12 // TodoItem vertical, EditableMarkdownView horizontal
    static let small: CGFloat = 10 // Common padding (pickerPadding)
    static let xSmall: CGFloat = 8 // EditableMarkdownView vertical, TodoList vertical
  }

  enum Spacing {
    static let medium: CGFloat = 10 // HomeScreen VStack spacing
    static let small: CGFloat = 8 // EditableMarkdownView button spacing
    static let none: CGFloat = 0 // UserPickerButton HStack spacing
  }

  enum Stroke {
    static let thin: CGFloat = 1 // UserPickerButton, EditableMarkdownView
  }

  enum Shadow {
    static let light: CGFloat = 1 // TodoList shadow
    static let medium: CGFloat = 2 // TodoStatusChip shadow
  }

  // MARK: - Component-specific Constants

  enum Component {
    enum UserPicker {
      static let buttonHeight: CGFloat = 40 // UserPickerButton segment height
      static let iconSize: CGFloat = 12 // UserPickerButton chevron
      static let dividerHeight: CGFloat = 20 // UserPickerButton divider
      static let dropdownHorizontalPadding: CGFloat = 3 // Dropdown button horizontal padding
      static let dropdownVerticalPadding: CGFloat = 10 // Dropdown button vertical padding
    }

    enum Memo {
      static let textEditorMinHeight: CGFloat = 100 // EditableMarkdownView
      static let textEditorMaxHeight: CGFloat = 300 // EditableMarkdownView
    }

    enum TodoList {
      static let itemHorizontalSpacing: CGFloat = 15 // TodoItem horizontal spacing
      static let itemVerticalPadding: CGFloat = 8 // TodoItem vertical padding
      static let statusPopoverPadding: CGFloat = 8 // Status popover padding
      static let statusPopoverSpacing: CGFloat = 8 // Status popover spacing
      static let dragHandleWidth: CGFloat = 20 // Drag handle width
      static let dragHandleOpacity: CGFloat = 0.6 // Drag handle opacity

      enum StatusChip {
        static let width: CGFloat = 70 // StatusChip width
        static let padding: CGFloat = 3 // StatusChip padding
        static let interactiveOpacity: CGFloat = 1.0 // Interactive opacity
        static let readOnlyOpacity: CGFloat = 0.7 // Read-only opacity
      }

      enum Typography {
        static let contentFont: Font = .title3 // Todo content font
        static let detailFont: Font = .callout // Todo detail font
      }
    }
  }
}
