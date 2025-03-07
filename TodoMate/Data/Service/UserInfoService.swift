//
//  UserInfoService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

enum UserInfoServiceError: Error {
    case failedToDecode
    case failedToEncode
    case failedToLoad
}

class UserInfoService: UserInfoServiceType {
    private let userDefaults: UserDefaults
    private let userInfoKey: String
    
    init(userDefaults: UserDefaults = .standard, userInfoKey: String = Const.UserInfoKey) {
        self.userDefaults = userDefaults
        self.userInfoKey = userInfoKey
    }

    func saveUserInfo(_ userInfo: AuthenticatedUser) throws {
        do {
            let encoded = try JSONEncoder().encode(userInfo)
            userDefaults.set(encoded, forKey: userInfoKey)
        } catch {
            throw UserInfoServiceError.failedToEncode
        }
    }

    func loadUserInfo() throws -> AuthenticatedUser {
        guard let savedData = userDefaults.data(forKey: userInfoKey) else {
            throw UserInfoServiceError.failedToLoad
        }
        
        do {
            let decoded = try JSONDecoder().decode(AuthenticatedUser.self, from: savedData)
            return decoded
        }
        catch {
            clearUserInfo()
            throw UserInfoServiceError.failedToDecode
        }
    }
    
    func clearUserInfo() {
        userDefaults.removeObject(forKey: userInfoKey)
    }

}
