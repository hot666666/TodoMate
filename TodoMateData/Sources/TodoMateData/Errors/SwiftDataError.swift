//
//  SwiftDataError.swift
//  TodoMateData
//
//  Created by agent on 1/15/26.
//

import Foundation

/// Data 계층 SwiftData Repository 에러
public enum SwiftDataError: Error {
  case saveFailed(underlying: Error)
  case fetchFailed(underlying: Error)
  case deleteFailed(underlying: Error)
}
