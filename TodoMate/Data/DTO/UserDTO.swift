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
    var nickname: String
    var gid: String?
}
#else
import FirebaseFirestore

struct UserDTO: Codable {
    @DocumentID var id: String?
    var nickname: String
    var gid: String?
}
#endif

extension UserDTO {
    static let stub: [UserDTO] = [.init(id: "test", nickname: "hs", gid: ""), .init(id: UUID().uuidString, nickname: "jy", gid: "")]
    
    func toModel() -> User {
        User(uid: self.id ?? "", nickname: self.nickname, gid: self.gid ?? "")
    }
}

extension User {
    func toDTO() -> UserDTO {
        UserDTO(id: self.uid, nickname: self.nickname, gid: self.gid)
    }
}

