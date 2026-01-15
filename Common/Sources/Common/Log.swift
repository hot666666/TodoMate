//
//  Log.swift
//  TodoMateInfra
//
//  Created by agent on 1/14/26.
//

import Foundation
import OSLog

/// 앱 전역에서 사용하는 로거
public enum Log {
  public enum Category: String {
    case auth = "Auth"
    case data = "Data"
    case network = "Network"
    case app = "App"
    case cache = "Cache"
    case connectivity = "Connectivity"
  }

  private static func logger(for category: Category) -> Logger {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "TodoMate", category: category.rawValue)
  }

  public static func debug(_ message: String, category: Category = .app) {
    logger(for: category).debug("\(message)")
  }

  public static func info(_ message: String, category: Category = .app) {
    logger(for: category).info("\(message)")
  }

  public static func warning(_ message: String, category: Category = .app) {
    logger(for: category).warning("\(message)")
  }

  public static func error(_ message: String, category: Category = .app) {
    logger(for: category).error("\(message)")
  }
}
