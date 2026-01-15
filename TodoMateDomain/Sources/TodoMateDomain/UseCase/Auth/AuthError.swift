//
//  AuthError.swift
//  TodoMateDomain
//
//  Created by hs on 7/12/25.
//

import Foundation

/// Domain 계층 인증 관련 비즈니스 에러
public enum AuthError: Error {
  case signInFailed(Error?)
  case signOutFailed(Error?)
  case notAuthenticated
}
