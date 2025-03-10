//
//  MockAuthenticationUseCase.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

@testable import TodoMate

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
