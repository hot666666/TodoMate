//
//  ContentViewMode.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

/// View mode for the main content area
// TODO: - Implement List View
enum ContentViewMode: String, CaseIterable, Identifiable {
  case board
//  case list
  case calendar

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .board: "view_kanban"
//    case .list: "format_list_bulleted"
    case .calendar: "calendar_today"
    }
  }

  var systemImage: String {
    switch self {
    case .board: "rectangle.split.3x1"
//    case .list: "list.bullet"
    case .calendar: "calendar"
    }
  }
}
