//
//  RefreshTrigger.swift
//  TodoMate
//
//  Created by hs on 7/14/25.
//

import SwiftUI

@Observable
final class RefreshTrigger {
  private(set) var value: Int = 0

  func trigger() {
    value += 1
  }
}
