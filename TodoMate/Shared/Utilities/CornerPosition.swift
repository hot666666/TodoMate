//
//  CornerPosition.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SwiftUI

struct CornerPosition: OptionSet {
  let rawValue: Int

  static let topLeading = CornerPosition(rawValue: 1 << 0)
  static let topTrailing = CornerPosition(rawValue: 1 << 1)
  static let bottomLeading = CornerPosition(rawValue: 1 << 2)
  static let bottomTrailing = CornerPosition(rawValue: 1 << 3)

  static let none: CornerPosition = []
  static let all: CornerPosition = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]

  var cornerRadii: RectangleCornerRadii {
    RectangleCornerRadii(
      topLeading: contains(.topLeading) ? CalendarDesignSystem.Layout.gridCornerRadius : 0,
      bottomLeading: contains(.bottomLeading) ? CalendarDesignSystem.Layout.gridCornerRadius : 0,
      bottomTrailing: contains(.bottomTrailing) ? CalendarDesignSystem.Layout.gridCornerRadius : 0,
      topTrailing: contains(.topTrailing) ? CalendarDesignSystem.Layout.gridCornerRadius : 0
    )
  }
}

extension CornerPosition {
  static func position(for index: Int, totalDays: Int) -> CornerPosition {
    let columnsPerRow = 7
    let totalRows = (totalDays + columnsPerRow - 1) / columnsPerRow
    let row = index / columnsPerRow
    let column = index % columnsPerRow

    var position: CornerPosition = .none

    // 첫 번째 행
    if row == 0 {
      if column == 0 {
        position.insert(.topLeading)
      } else if column == columnsPerRow - 1 {
        position.insert(.topTrailing)
      }
    }

    // 마지막 행
    if row == totalRows - 1 {
      if column == 0 {
        position.insert(.bottomLeading)
      } else if column == columnsPerRow - 1 {
        position.insert(.bottomTrailing)
      }
    }

    return position
  }
}
