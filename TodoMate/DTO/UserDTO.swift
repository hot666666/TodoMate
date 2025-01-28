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
}
#else
import FirebaseFirestore

struct UserDTO: Codable {
    @DocumentID var id: String?
    var nickname: String
}
#endif

extension UserDTO {
    static let stub: [UserDTO] = [.init(id: "test", nickname: "hs"), .init(id: UUID().uuidString, nickname: "jy")]
    
    func toModel() -> User {
        User(nickname: self.nickname, uid: self.id ?? "")
    }
}

extension User {
    func toDTO() -> UserDTO {
        UserDTO(id: self.uid, nickname: self.nickname)
    }
}

