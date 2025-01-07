//
//  UserDTO.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Foundation

#if PREVIEW
struct UserDTO {
    var id: String?
    var name: String
}
#else
import FirebaseFirestore

struct UserDTO: Codable {
    @DocumentID var id: String?
    var name: String
}
#endif

extension UserDTO {
    func toModel() -> User {
        User(name: self.name, fid: self.id!)
    }
}

extension User {
    func toDTO() -> UserDTO {
        UserDTO(id: self.fid, name: self.name)
    }
}

