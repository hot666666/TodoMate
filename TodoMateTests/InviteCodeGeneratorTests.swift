//
//  InviteCodeGeneratorTests.swift
//  TodoMateTests
//
//  Created by agent on 12/28/25.
//

import Testing

@testable import TodoMate

struct InviteCodeGeneratorTests {
  @Test func generatesCodeVerification() {
    let generator = InviteCodeGenerator()
    let code = generator.generate()

    // 1. 길이는 6자리여야 함
    #expect(code.count == 6)

    // 2. 허용된 문자만 포함해야 함 (알파벳 대문자 + 숫자)
    let allowedCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    #expect(code.allSatisfy { allowedCharacters.contains($0) })
  }
}
