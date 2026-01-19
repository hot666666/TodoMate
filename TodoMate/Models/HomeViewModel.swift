//
//  HomeViewModel.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
  let boardViewModel = BoardViewModel()
  let calendarViewModel: TodoCalendarViewModel

  init(container: CoreDIContainer) {
    calendarViewModel = TodoCalendarViewModel(container: container)
  }
}
