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

// MARK: Data Layer

class MockUserInfoService: UserInfoServiceType {
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
