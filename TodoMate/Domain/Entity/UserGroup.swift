//
//  Group.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

struct UserGroup {
    let id: String
    var uids: [String]
}

extension UserGroup {
    static let stub: UserGroup = .init(id: "1", uids: ["hs", "jy"])
}
