//
//  User.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import SwiftUI

@Observable
class User: Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var fid: String?
    
    init(name: String = "", fid: String? = nil) {
        self.name = name
        self.fid = fid
    }
}

extension User {
    func toDTO() -> UserDTO {
        UserDTO(id: self.fid, name: self.name)
    }
}

extension User {
    static var stub: [User] {
        [.init(name: "유저1", fid: UUID().uuidString), .init(name: "유저2", fid: UUID().uuidString)]
    }
}
