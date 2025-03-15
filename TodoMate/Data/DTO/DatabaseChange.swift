//
//  DatabaseChange.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

enum DatabaseChange<T> {
  case added(T)
  case modified(T)
  case removed(T)
}

extension DatabaseChange {
  var data: T {
    switch self {
    case let .added(data), let .modified(data), let .removed(data):
      return data
    }
  }
}
