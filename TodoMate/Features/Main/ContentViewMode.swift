//
//  ContentViewMode.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

enum ContentViewMode: String, CaseIterable, Identifiable {
  case board
  case calendar

  var id: Self { self }

  var systemImage: String {
    switch self {
    case .board: "rectangle.split.3x1"
    case .calendar: "calendar"
    }
  }
}
