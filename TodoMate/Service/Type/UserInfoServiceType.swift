//
//  StubUserInfoService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol UserInfoServiceType {
    func saveUserInfo(_ userInfo: UserInfo)
    func loadUserInfo() -> UserInfo
}

class StubUserInfoService: UserInfoServiceType {
    func saveUserInfo(_ userInfo: UserInfo) { }

    func loadUserInfo() -> UserInfo { .stub }
}

