//
//  UserInfo.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

struct UserInfo: Codable {
    let id: String
    let token: String
    let gid: String
    
    static let empty = UserInfo(id: "", token: "", gid: "")
    static let stub = UserInfo(id: User.stub[0].uid, token: UUID().uuidString, gid: "")
    static let hasGroupStub = UserInfo(id: User.stub[0].uid, token: UUID().uuidString, gid: UserGroup.stub.id)
}
