//
//  UserDefaults+.swift
//  TodoMate
//
//  Created by agent on 1/6/26.
//

import Foundation

import Common

// MARK: - UserDefaults Extension

extension UserDefaults {
  /// In-memory UserDefaults for preivews/tests
  static let preview: UserDefaults = {
    let suiteName = "preview"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }()

  func set(_ value: Any?, for key: UserDefaultsKey) {
    set(value, forKey: key.rawValue)
  }

  func string(for key: UserDefaultsKey) -> String? {
    string(forKey: key.rawValue)
  }

  func bool(for key: UserDefaultsKey, default defaultValue: Bool = false) -> Bool {
    object(forKey: key.rawValue) as? Bool ?? defaultValue
  }

  func double(for key: UserDefaultsKey) -> Double {
    double(forKey: key.rawValue)
  }

  func data(for key: UserDefaultsKey) -> Data? {
    data(forKey: key.rawValue)
  }

  func removeObject(for key: UserDefaultsKey) {
    removeObject(forKey: key.rawValue)
  }
}
