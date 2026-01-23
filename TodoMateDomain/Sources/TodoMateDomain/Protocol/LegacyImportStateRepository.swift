//
//  LegacyImportStateRepository.swift
//  TodoMateDomain
//
//  Created by agent on 1/23/26.
//

import Foundation

public protocol LegacyImportStateRepository: Sendable {
  /// Check if legacy import is already completed
  func isImported() -> Bool

  /// Set the legacy import completion status
  func setImported(_ imported: Bool)
}
