//
//  MockFetchTodosByUserUseCase.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

@testable import TodoMate
import Foundation

final class MockFetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType {
    var result: [String: [Todo]]?
    var shouldThrowError = false
    
    func execute(for user: AuthenticatedUser) async throws -> [String: [Todo]] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"])
        }
        return result ?? [:]
    }
}
