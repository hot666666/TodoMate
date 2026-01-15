//
//  AuthStoreError.swift
//  TodoMateData
//
//  Created by agent on 1/15/26.
//

import Foundation

public enum AuthServiceError: Error {
  case noActiveWindowScene
  case userTokenNotFound
  case signInFailed(underlying: Error)
  case signOutFailed(underlying: Error)
}
