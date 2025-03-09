//
//  TodoMateTests.swift
//  TodoMateTests
//
//  Created by hs on 3/5/25.
//

import Testing
@testable import TodoMate

struct TodoMateTests {
    @Test(.disabled("비활성"))
    func example() async throws {
        #expect(1+1==2, "1+1=2")
    }
}

/*
 - 인터페이스 정의하기
 - 하위 계층부터 테스트를 진행 -> 상위 계층에선 Mock 또는 Dummy로 대체
 - TestFixtures를 통해 사용되는 Mock 관리
    - 공통요소는 Suite안에 정의하고 다른 요소는 TestFixtures로 직접 사용
    - Mock이 여러 동작을 수행할 때는 Behavior를 지정하여 구현
*/
