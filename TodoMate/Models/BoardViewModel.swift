//
//  BoardViewModel.swift
//  TodoMate
//
//  Created by agent on 1/19/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class BoardViewModel {
  var dateFilter: DateFilter = .today
  var scrollPosition: BoardScrollPosition? = .leading
}
