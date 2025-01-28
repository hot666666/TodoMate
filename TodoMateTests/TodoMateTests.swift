//
//  TodoMateTests.swift
//  TodoMateTests
//
//  Created by hs on 1/28/25.
//

import Testing

struct TodoMateTests {

    @Test func example() async throws {
        /// 가장 간단한 테스트 케이스
        let result = 1 + 1
        #expect(result == 2)
    }
}
