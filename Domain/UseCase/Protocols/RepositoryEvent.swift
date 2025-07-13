//
//  RepositoryEvent.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import Foundation

enum RepositoryEvent<T> {
  case added(T)
  case modified(T)
  case removed(T)
  case error(Error)
}
