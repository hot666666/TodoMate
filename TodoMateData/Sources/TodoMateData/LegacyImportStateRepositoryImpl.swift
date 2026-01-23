//
//  LegacyImportStateRepositoryImpl.swift
//  TodoMateData
//
//  Created by agent on 1/23/26.
//

import Common
import Foundation
import TodoMateDomain

public final class LegacyImportStateRepositoryImpl: LegacyImportStateRepository, @unchecked Sendable {
  private let userDefaults: UserDefaults

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  public func isImported() -> Bool {
    userDefaults.bool(for: .hasImportedLegacyData)
  }

  public func setImported(_ imported: Bool) {
    userDefaults.set(imported, for: .hasImportedLegacyData)
  }
}
