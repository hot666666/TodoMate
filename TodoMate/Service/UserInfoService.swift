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

    func saveUserInfo(_ userInfo: AuthenticatedUser?) {
        if let encoded = try? JSONEncoder().encode(userInfo) {
            userDefaults.set(encoded, forKey: userInfoKey)
        }
    }

    func loadUserInfo() -> AuthenticatedUser? {
        guard let savedData = userDefaults.data(forKey: userInfoKey) else {
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(AuthenticatedUser.self, from: savedData)
            return decoded
        }
        catch {
            print("Failed to decode data")
            resetUserInfo()
            return nil
        }
    }
}
extension UserInfoService {
    private func resetUserInfo() {
        userDefaults.removeObject(forKey: userInfoKey)
    }
}
