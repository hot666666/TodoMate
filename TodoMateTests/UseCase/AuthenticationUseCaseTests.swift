//
//  AuthManagerTests.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

import Testing
import Foundation
@testable import TodoMate

@Suite("AuthenticationUseCase Tests")
struct AuthenticationUseCaseTests {
    private let mockUser: User
    private var mockWidgetDataManager: MockWidgetDataManager
    private var mockUserInfoServiceWithoutUserInfo: MockUserInfoService
    private var mockAuthServiceSuccess: MockAuthService
    private var mockAuthServiceFailure: MockAuthService
    
    init() {
        mockUser = User(uid: "uid", nickname: "", gid: "1")
        
        mockWidgetDataManager = MockWidgetDataManager()
        
        mockUserInfoServiceWithoutUserInfo = MockUserInfoService(existingUserInfo: nil)
        
        mockAuthServiceSuccess = MockAuthService(shouldSignInSuccess: true, signInReturn: mockUser)
        mockAuthServiceFailure = MockAuthService(shouldSignInSuccess: false)
    }
    
    @Test("로그인 성공")
    func test_signIn() async throws {
        // Given
        let authenticationUseCase = AuthenticationUseCase(authService: mockAuthServiceSuccess,
                                                          userInfoService: mockUserInfoServiceWithoutUserInfo,
                                                          widgetDataManager: mockWidgetDataManager)
        
        // When
        let result = await authenticationUseCase.signIn()
        
        // Then
        switch result {
        case .success(_):
            #expect(Bool(true), "로그인 성공해야함")
        case .failure(let error):
            #expect(Bool(false), "로그인 성공해야함: \(error)")
        }
    }
    
    @Test("로그인 실패")
    func test_signIn_failure() async throws {
        // Given
        let authenticationUseCase = AuthenticationUseCase(authService: mockAuthServiceFailure,
                                                          userInfoService: mockUserInfoServiceWithoutUserInfo,
                                                          widgetDataManager: mockWidgetDataManager)
        
        // When
        let result = await authenticationUseCase.signIn()
        
        // Then
        switch result {
        case .success(_):
            #expect(Bool(false), "로그인 실패해야함")
        case .failure(_):
            #expect(Bool(true), "로그인 실패해야함")
        }
    }
}
