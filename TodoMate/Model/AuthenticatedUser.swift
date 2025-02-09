//
//  UserInfo.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

struct AuthenticatedUser: Codable {
    let id: String
    let token: String
    let gid: String
    
    static let empty = AuthenticatedUser(id: "", token: "", gid: "")
    static let stub = AuthenticatedUser(id: User.stub[0].uid, token: UUID().uuidString, gid: "")
    static let hasGroupStub = AuthenticatedUser(id: User.stub[0].uid, token: UUID().uuidString, gid: UserGroup.stub.id)
}
