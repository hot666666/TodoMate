//
//  TodoCalendarViewModel.swift
//  TodoMate
//
//  Created by agent on 1/11/26.
//

import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class TodoCalendarViewModel {
  var todos: [Todo] = []
  var currentDate: Date = .init() {
    didSet {
      updateObservation()
    }
  }

  private let observeTodosUseCase: ObserveTodosUseCase
  private var observationTask: Task<Void, Never>?

  init(observeTodosUseCase: ObserveTodosUseCase) {
    self.observeTodosUseCase = observeTodosUseCase
    updateObservation()
  }

  convenience init(container: CoreDIContainer) {
    self.init(observeTodosUseCase: container.observeTodosUseCase)
  }

  func updateObservation() {
    observationTask?.cancel()

    // Calculate start/end of the 6-week calendar grid
    // Logic must match CalendarQueryWrapper's grid calculation
    let calendar = Calendar.current
    guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else { return }
    let monthStart = monthInterval.start

    // Calendar view often shows previous month's days to fill the first row
    let weekday = calendar.component(.weekday, from: monthStart)
    let startOffset = weekday - 1
    let startDisplayDate = calendar.date(byAdding: .day, value: -startOffset, to: monthStart)!

    // 42 days (6 weeks)
    let endDisplayDate = calendar.date(byAdding: .day, value: 42, to: startDisplayDate)!

    let range = startDisplayDate ... endDisplayDate

    observationTask = Task {
      for await newTodos in observeTodosUseCase.execute(dateRange: range) {
        self.todos = newTodos
      }
    }
  }
}

extension TodoCalendarViewModel {
  static var preview: TodoCalendarViewModel {
    TodoCalendarViewModel(container: .preview)
  }
}
