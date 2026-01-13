//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 1/13/26.
//

import SwiftUI

struct HomeView: View {
  @Environment(\.overlayManager) private var overlay
  let naviManager: NavigationManager

  var body: some View {
    switch naviManager.viewMode {
    case .board:
      BoardView()
        .onKeyPress(.escape) {
          if overlay?.isEmpty == false {
            overlay?.dismissTop()
            return .handled
          }
          return .ignored
        }
    case .calendar:
      CalendarView()
        .onKeyPress(.escape) {
          if overlay?.isEmpty == false {
            overlay?.dismissTop()
            return .handled
          }
          return .ignored
        }
    }
  }
}
