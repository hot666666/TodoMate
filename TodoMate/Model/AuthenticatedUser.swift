//
//  AuthenticatedUser.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Foundation

// TODO: - name add
struct AuthenticatedUser: Codable {
    let uid: String
    let gid: String
    
    static let empty = AuthenticatedUser(uid: "", gid: "")
    static let stub = AuthenticatedUser(uid: User.stub[0].uid, gid: "")
    static let hasGroupStub = AuthenticatedUser(uid: User.stub[0].uid, gid: UserGroup.stub.id)
}
