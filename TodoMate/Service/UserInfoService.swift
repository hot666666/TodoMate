//
//  UserInfoService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

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

