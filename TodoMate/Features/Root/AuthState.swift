//
//  AuthState.swift
//  Todo
//
//  Created by hs on 6/30/25.
//

enum AuthState {
  case loading
  case authenticated(UserSession)
  case unauthenticated
}
