//
//  FetchGroupUsersUseCase.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

protocol FetchGroupUsersUseCaseType {
  func execute() -> [User]
}

final class FetchGroupUsersUseCase: FetchGroupUsersUseCaseType {
  func execute() -> [User] {
    []
  }
}

class StubFetchGroupUsersUseCase: FetchGroupUsersUseCaseType {
  func execute() -> [User] {
    User.stub
  }
}
