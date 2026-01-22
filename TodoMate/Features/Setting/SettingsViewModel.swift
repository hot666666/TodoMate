//
//  SettingsViewModel.swift
//  TodoMate
//
//  Created by hs on 2025-01-23.
//

import Foundation
import Observation
import TodoMateDomain

@MainActor
@Observable
final class SettingsViewModel {
  enum ImportState {
    case idle
    case importing(progress: Double)
    case completed
    case failed(Error)
  }

  private let importLegacyDataUseCase: ImportLegacyDataUseCase
  var importState: ImportState = .idle
  var showImportConfirmation: Bool = false

  init(importLegacyDataUseCase: ImportLegacyDataUseCase) {
    self.importLegacyDataUseCase = importLegacyDataUseCase
  }

  func isValidTargetForImport(user: User?) -> Bool {
    guard let user else { return false }

    // Check createdAt < 2025-08-24
    // 2025-08-24 00:00:00 UTC
    let calendar = Calendar(identifier: .gregorian)
    let components = DateComponents(year: 2025, month: 8, day: 24)
    guard let targetDate = calendar.date(from: components) else { return false }

    return user.createdAt < targetDate
  }

  func importLegacyData(userId: String) async {
    importState = .importing(progress: 0.0)

    do {
      for try await progress in importLegacyDataUseCase.execute(userId: userId) {
        importState = .importing(progress: progress)
      }
      importState = .completed
    } catch {
      importState = .failed(error)
    }
  }
}
