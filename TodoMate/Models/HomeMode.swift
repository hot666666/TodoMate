//
//  HomeMode.swift
//  TodoMate
//
//  Created by hs on 1/5/26.
//

import SwiftUI

enum HomeMode: String, CaseIterable, Identifiable {
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
