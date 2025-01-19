//
//  User.swift
//  TodoMate_
//
//  Created by hs on 12/28/24.
//

import Foundation

@Observable
class User: Identifiable {
    let id: String = UUID().uuidString
    var nickname: String
    var uid: String
    
    init(nickname: String, uid: String = UUID().uuidString) {
        self.nickname = nickname
        self.uid = uid
    }
}
extension User {
    static let stub: [User] = [.init(nickname: "hs"), .init(nickname: "jy")]
}
