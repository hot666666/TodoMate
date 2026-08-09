//
//  AppEnvironment.swift
//  Common
//
//  Environment-specific configuration for the app.
//
//  Created by hs on 1/22/26.
//

import Foundation

public enum AppEnvironment {
  public enum Container {
    #if DEBUG
      public static let name = "TodoMateDebug"
      public static let appGroupIdentifier = "8PRWAG4355.io.hotcs6.TodoMateDebug"
    #else
      public static let name = "TodoMate"
      public static let appGroupIdentifier = "8PRWAG4355.io.hotcs6.TodoMate"
    #endif
  }

  public enum Widget {
    #if DEBUG
      public static let kind = "TodoMateWidgetDev"
    #else
      public static let kind = "TodoMateWidget"
    #endif
  }
}
