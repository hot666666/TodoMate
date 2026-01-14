//
//  AuthServiceError.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import Foundation

public enum AuthServiceError: Error {
  case noActiveWindowScene
  case userTokenNotFound
  case dataConversionFailed
  case unknownError(Error?)
  case customError(String)
}
