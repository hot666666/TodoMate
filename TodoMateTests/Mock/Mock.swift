//
//  Mock.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Foundation
@testable import TodoMate

// MARK: - UseCase

struct MockAuthenticationUseCase: AuthenticationUseCaseType {
    private let shouldSignInSuccess: Bool
    private let signInReturn: AuthenticatedUser?
    init(shouldSignInSuccess: Bool = false, signInReturn: AuthenticatedUser? = nil) {
        self.shouldSignInSuccess = shouldSignInSuccess
        self.signInReturn = signInReturn
    }
    
    func signOut() async {}
    func signIn() async -> Result<AuthenticatedUser, AuthenticationUseCaseError> {
        shouldSignInSuccess ? .success(signInReturn ?? .stub) : .failure(.signInFailed(""))
    }
}

struct MockFetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType {
    private let excuteReturn: AuthenticatedUser?
    init(excuteReturn: AuthenticatedUser? = nil) { self.excuteReturn = excuteReturn }

    func execute() -> AuthenticatedUser? { excuteReturn }
}

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

// MARK: Data Layer

struct MockTodoRepository: TodoRepositoryType {
    // Behavior를 통해 각 메서드의 동작을 테스트마다 자유롭게 정의
    var createTodoHandler: ((TodoDTO) async throws -> TodoDTO)?
    var fetchTodosByUserHandler: ((String, Date, Date) async throws -> [TodoDTO])?
    var fetchTodosByGroupHandler: ((String, Date, Date) async throws -> [TodoDTO])?
    var updateTodoHandler: ((TodoDTO) async throws -> Void)?
    var deleteTodoHandler: ((String) async throws -> Void)?
    
    func createTodo(_ todoDTO: TodoDTO) async throws -> TodoDTO {
        guard let handler = createTodoHandler else { throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "createTodoHandler not set"]) }
        return try await handler(todoDTO)
    }
    
    func fetchTodos(userId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        guard let handler = fetchTodosByUserHandler else { return [] }
        return try await handler(userId, startDate, endDate)
    }
    
    func fetchTodos(groupId: String, startDate: Date, endDate: Date) async throws -> [TodoDTO] {
        guard let handler = fetchTodosByGroupHandler else { return [] }
        return try await handler(groupId, startDate, endDate)
    }
    
    func updateTodo(todo: TodoDTO) async throws {
        guard let handler = updateTodoHandler else { return }
        try await handler(todo)
    }
    
    func deleteTodo(todoId: String) async throws {
        guard let handler = deleteTodoHandler else { return }
        try await handler(todoId)
    }
}

final class MockTodoService: TodoServiceType {
    var fetchTodayResult: [Todo] = []
    
    func fetchTodos() async throws -> [Todo] { [] }
    func create(from todo: Todo) async -> Todo? { nil }
    func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] { [:] }
    func fetchToday(groupId: String) async -> [Todo] { fetchTodayResult }
    func update(_ todo: Todo) { }
    func remove(_ todo: Todo) { }
}

final class MockTodoOrderService: TodoOrderServiceType {
    var loadOrderResult: [String]?
    var savedOrder: [String]?
    var savedDate: Date?
    
    func loadOrder(for date: Date) -> [String]? { loadOrderResult }
    func saveOrder(_ order: [String], for date: Date) {
        savedOrder = order
        savedDate = Calendar.current.startOfDay(for: date)
    }
}

struct MockTodoOrderRepository: TodoOrderRepositoryType {
    // load만 테스트하기 위해 save는 더미로 구현
    
    var loadOrderHandler: (() -> [String])?
    var loadDateHandler: (() -> Date?)?

    func saveOrder(_ order: [String]) { }
    func saveDate(_ date: Date) { }

    func loadOrder() -> [String] {
        loadOrderHandler?() ?? []
    }

    func loadDate() -> Date? {
        loadDateHandler?()
    }
}

final class MockUserInfoService: UserInfoServiceType {
    private var userInfo: AuthenticatedUser?
    
    init(existingUserInfo: AuthenticatedUser? = nil) {
        self.userInfo = existingUserInfo
    }
    
    func saveUserInfo(_ userInfo: AuthenticatedUser) throws {
        self.userInfo = userInfo
    }
    
    func loadUserInfo() throws -> AuthenticatedUser {
        guard let userInfo = userInfo else {
            throw NSError(domain: "UserInfoServiceError", code: 0, userInfo: nil)
        }
        return userInfo
    }
    
    func clearUserInfo() {
        userInfo = nil
    }
}

struct MockAuthService: AuthServiceType {
    private let shouldSignInSuccess: Bool
    private let signInReturn: User?
    
    init(shouldSignInSuccess: Bool = false, signInReturn: User? = nil) {
        self.shouldSignInSuccess = shouldSignInSuccess
        self.signInReturn = signInReturn
    }
    
    func signIn() async throws -> User {
        if shouldSignInSuccess {
            return signInReturn ?? .stub[0]
        } else {
            throw NSError(domain: "AuthError", code: 0, userInfo: nil)
        }
    }
    func signOut() async {}
}

struct MockWidgetDataManager: WidgetDataManagerType {
    func save(_ todo: WidgetTodo) async {}
    func remove(_ todoFid: String?) async {}
    func removeAll () async {}
}
