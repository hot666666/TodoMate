//
//  StubUserInfoService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

// TODO: - 명칭 통일
protocol UserInfoServiceType {
    func saveUserInfo(_ userInfo: AuthenticatedUser) throws
    func loadUserInfo() throws -> AuthenticatedUser
    func clearUserInfo()
}

class StubUserInfoService: UserInfoServiceType {
    func saveUserInfo(_ userInfo: AuthenticatedUser) throws { }
    func loadUserInfo() throws -> AuthenticatedUser { .stub }
    func clearUserInfo() { }
}

