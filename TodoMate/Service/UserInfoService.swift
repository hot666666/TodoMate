//
//  UserInfoService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

protocol UserInfoServiceType {
    func saveUserInfo(_ userInfo: UserInfo)
    func loadUserInfo() -> UserInfo
}

class UserInfoService: UserInfoServiceType {
    private let userDefaults = UserDefaults.standard
    private let userInfoKey = Const.UserInfoKey

    func saveUserInfo(_ userInfo: UserInfo) {
        if let encoded = try? JSONEncoder().encode(userInfo) {
            userDefaults.set(encoded, forKey: userInfoKey)
        }
    }

    func loadUserInfo() -> UserInfo {
        if let savedData = userDefaults.data(forKey: userInfoKey),
           let decoded = try? JSONDecoder().decode(UserInfo.self, from: savedData) {
            return decoded
        }
        return .empty // 기본값
    }
}

class StubUserInfoService: UserInfoServiceType {
    func saveUserInfo(_ userInfo: UserInfo) { }

    func loadUserInfo() -> UserInfo { .stub }
}

