//
//  TodoOrderServiceTests.swift
//  TodoMate
//
//  Created by hs on 3/7/25.
//

import Testing
import Foundation
@testable import TodoMate

fileprivate struct TestFixtures {
    static let calendar = Calendar.current
    static let now = Date()
    static let mockOrder = ["todo1-fid1", "todo2-fid2", "todo3-fid3"]
    static let mockDate = calendar.startOfDay(for: now)
    static let differentDate = calendar.date(byAdding: .day, value: 1, to: mockDate)!

    // loadOrder 성공 시나리오 (같은 날짜)
    static func todoOrderRepositoryForLoadSuccess() -> MockTodoOrderRepository {
        var repo = MockTodoOrderRepository()
        repo.loadOrderHandler = { TestFixtures.mockOrder }
        repo.loadDateHandler = { TestFixtures.mockDate }
        return repo
    }

    // loadOrder 실패 시나리오 (저장된 날짜 없음)
    static func todoOrderRepositoryForLoadFailureNoDate() -> MockTodoOrderRepository {
        var repo = MockTodoOrderRepository()
        repo.loadOrderHandler = { TestFixtures.mockOrder }
        repo.loadDateHandler = { nil }
        return repo
    }

    // loadOrder 실패 시나리오 (다른 날짜)
    static func todoOrderRepositoryForLoadFailureDifferentDate() -> MockTodoOrderRepository {
        var repo = MockTodoOrderRepository()
        repo.loadOrderHandler = { TestFixtures.mockOrder }
        repo.loadDateHandler = { calendar.date(byAdding: .day, value: -1, to: TestFixtures.mockDate)! }
        return repo
    }
}

@Suite("TodoOrderService Tests")
struct TodoOrderServiceTests {
    let mockOrder = TestFixtures.mockOrder
    let mockDate = TestFixtures.mockDate
    let differentDate = TestFixtures.differentDate

    @Suite("loadOrder 메서드 테스트")
    struct LoadOrderTests {
        @Test("loadOrder 성공 - 같은 날짜")
        func loadOrderSucceedsWithSameDate() {
            // Given
            let service = TodoOrderService(todoOrderRepository: TestFixtures.todoOrderRepositoryForLoadSuccess())

            // When
            let result = service.loadOrder(for: TestFixtures.mockDate)

            // Then
            #expect(result != nil, "같은 날짜일 때 order가 반환되어야 함")
            #expect(result == TestFixtures.mockOrder, "반환된 order는 저장된 mockOrder와 같아야 함")
        }

        @Test("loadOrder 실패 - 저장된 날짜 없음")
        func loadOrderFailsWithNoSavedDate() {
            // Given
            let service = TodoOrderService(todoOrderRepository: TestFixtures.todoOrderRepositoryForLoadFailureNoDate())

            // When
            let result = service.loadOrder(for: TestFixtures.mockDate)

            // Then
            #expect(result == nil, "저장된 날짜가 없으면 nil이 반환되어야 함")
        }

        @Test("loadOrder 실패 - 다른 날짜")
        func loadOrderFailsWithDifferentDate() {
            // Given
            let service = TodoOrderService(todoOrderRepository: TestFixtures.todoOrderRepositoryForLoadFailureDifferentDate())

            // When
            let result = service.loadOrder(for: TestFixtures.mockDate)

            // Then
            #expect(result == nil, "다른 날짜일 때 nil이 반환되어야 함")
        }
    }
}
