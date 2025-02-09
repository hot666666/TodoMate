//
//  StubUserInfoService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol UserInfoServiceType {
    func saveUserInfo(_ userInfo: AuthenticatedUser)
    func loadUserInfo() -> AuthenticatedUser
}

class StubUserInfoService: UserInfoServiceType {
    func saveUserInfo(_ userInfo: AuthenticatedUser) { }

    func loadUserInfo() -> AuthenticatedUser { .stub }
}

