//
//  User.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import Foundation

struct User {
    var uid: String
    var nickname: String
    var gid: String
    
    init(uid: String = UUID().uuidString, nickname: String, gid: String = "") {
        self.uid = uid
        self.nickname = nickname
        self.gid = gid
    }
    
}

extension User {
    static let stub: [User] = [.init(uid: "hs", nickname: "hs", gid: UserGroup.stub.id), .init(uid: "jy", nickname: "jy", gid: UserGroup.stub.id)]
}
