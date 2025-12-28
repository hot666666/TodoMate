//
//  Log.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import OSLog

/// 앱 전역에서 사용하는 로거
enum Log {
  enum Category: String {
    case auth = "Auth"
    case sync = "Sync"
    case network = "Network"
    case general = "General"
  }

  private static func logger(for category: Category) -> Logger {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "TodoMate", category: category.rawValue)
  }

  static func debug(_ message: String, category: Category = .general) {
    logger(for: category).debug("\(message)")
  }

  static func info(_ message: String, category: Category = .general) {
    logger(for: category).info("\(message)")
  }

  static func warning(_ message: String, category: Category = .general) {
    logger(for: category).warning("\(message)")
  }

  static func error(_ message: String, category: Category = .general) {
    logger(for: category).error("\(message)")
  }
}
