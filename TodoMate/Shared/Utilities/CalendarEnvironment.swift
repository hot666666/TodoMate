//
//  CalendarEnvironment.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import SwiftUI

struct CalendarCellHeight: EnvironmentKey {
  static let defaultValue: CGFloat = 90
}

extension EnvironmentValues {
  var calendarCellHeight: CGFloat {
    get { self[CalendarCellHeight.self] }
    set { self[CalendarCellHeight.self] = newValue }
  }
}
