//
//  MockFetchAuthenticatedUserUseCase.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

@testable import TodoMate

struct MockFetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType {
  private let excuteReturn: AuthenticatedUser?
  init(excuteReturn: AuthenticatedUser? = nil) { self.excuteReturn = excuteReturn }

  func execute() -> AuthenticatedUser? { excuteReturn }
}
