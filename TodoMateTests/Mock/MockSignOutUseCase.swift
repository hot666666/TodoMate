//
//  MockSignOutUseCase.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

@testable import TodoMate

final class MockSignOutUseCase: SignOutUseCaseType {
  private let shouldSignOutSuccess: Bool

  init(shouldSignOutSuccess: Bool) {
    self.shouldSignOutSuccess = shouldSignOutSuccess
  }

  func execute() async {
    // SignOutUseCase는 성공 여부와 상관없이 아무런 동작을 하지 않음
    // 실제 SignOut의 경우 내부에서 오류가 발생하더라도 별도 처리하지 않으므로 여기서도 처리하지 않음
  }
}
