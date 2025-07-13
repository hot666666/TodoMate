//
//  CalendarDesignSystem.swift
//  Todo
//
//  Created by hs on 6/25/25.
//

import SwiftUI

enum CalendarDesignSystem {
  enum Layout {
    static let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 7)
    static let gridSpacing: CGFloat = 2
    static let horizontalPadding: CGFloat = 24
    static let headerVerticalPadding: CGFloat = 16
    static let gridContainerPadding: CGFloat = 2
    static let gridContainerBottomPadding: CGFloat = 32
    static let gridCornerRadius: CGFloat = 16
  }

  enum Animation {
    static let defaultDuration: CGFloat = 0.2
    static let dropDuration: CGFloat = 0.3
    static let dragOpacity: CGFloat = 0.6
    static let dragScale: CGFloat = 0.95
  }

  // MARK: - Design Tokens

  enum CornerRadius {
    static let large: CGFloat = 16
    static let medium: CGFloat = 8
    static let small: CGFloat = 4
  }

  enum Padding {
    static let large: CGFloat = 24
    static let medium: CGFloat = 16
    static let small: CGFloat = 8
    static let xSmall: CGFloat = 2
  }

  enum Spacing {
    static let medium: CGFloat = 12
    static let small: CGFloat = 8
    static let xSmall: CGFloat = 2
  }

  // MARK: - Component-specific Constants

  enum Component {
    enum DayCell {
      static let minHeight: CGFloat = 60
      static let cornerRadius: CGFloat = 8
    }

    enum TodoItem {
      static let horizontalPadding: CGFloat = 6
      static let verticalPadding: CGFloat = 3
      static let cornerRadius: CGFloat = 5
      static let spacing: CGFloat = 4
      static let font: Font = .system(size: 11, weight: .medium, design: .rounded)
      static let dragPreviewOpacity: CGFloat = 0.7
      static let dragPreviewHorizontalPadding: CGFloat = 8
      static let dragPreviewVerticalPadding: CGFloat = 4
    }

    enum Header {
      static let buttonSize: CGFloat = 24
      static let verticalPadding: CGFloat = 16
      static let navigationButtonSize: CGFloat = 32
      static let navigationPadding: CGFloat = 8
      static let todayButtonSize: CGFloat = 14
      static let navigationIconSize: CGFloat = 16
      static let todayScale: CGFloat = 0.8
      static let minTitleWidth: CGFloat = 150
    }

    enum Weekday {
      static let topPadding: CGFloat = 10
      static let bottomPadding: CGFloat = 5
    }

    enum Typography {
      static let dayFont: Font = .caption
      static let headerFont: Font = .system(size: 28, weight: .bold, design: .rounded)
      static let weekdayFont: Font = .caption2
    }
  }

  enum Weekdays {
    static let korean = ["일", "월", "화", "수", "목", "금", "토"]
  }
}
