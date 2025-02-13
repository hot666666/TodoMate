//
//  AuthenticatedUser.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

struct AuthenticatedUser: Codable {
    let uid: String
    let token: String
    let gid: String
    
    static let empty = AuthenticatedUser(uid: "", token: "", gid: "")
    static let stub = AuthenticatedUser(uid: User.stub[0].uid, token: UUID().uuidString, gid: "")
    static let hasGroupStub = AuthenticatedUser(uid: User.stub[0].uid, token: UUID().uuidString, gid: UserGroup.stub.id)
}
