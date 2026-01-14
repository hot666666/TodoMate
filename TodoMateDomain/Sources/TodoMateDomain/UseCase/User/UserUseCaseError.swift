//
//  UserUseCaseError.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

import Foundation

public enum UserUseCaseError: Error {
  case userNotFound
}

public enum UpdateUserError: Error, Equatable {
  case emptyDisplayName
  case displayNameTooLong(maxLength: Int)
}
