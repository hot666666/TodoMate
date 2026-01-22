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

  // Target Date: 2025-08-24 00:00:00 UTC
  // Users created before this date are eligible for legacy import.
  private let legacyImportCutoffDate: Date? = {
    var components = DateComponents()
    components.year = 2025
    components.month = 8
    components.day = 24
    components.timeZone = TimeZone(identifier: "UTC")
    return Calendar(identifier: .gregorian).date(from: components)
  }()

  func isValidTargetForImport(user: User?) -> Bool {
    guard let user, let cutoffDate = legacyImportCutoffDate else { return false }
    return user.createdAt < cutoffDate
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
