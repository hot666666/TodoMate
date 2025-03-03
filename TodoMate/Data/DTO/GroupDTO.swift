//
//  GroupDTO.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

#if PREVIEW
struct GroupDTO {
    var id: String?
    var uids: [String]
}
#else
import FirebaseFirestore

struct GroupDTO: Codable {
    @DocumentID var id: String?
    var uids: [String]
}
#endif

extension GroupDTO {
    static let stub = GroupDTO(id: "1", uids: [User.stub[0].uid, User.stub[1].uid])
    
    func toModel() -> UserGroup {
        return UserGroup(id: self.id ?? "", uids: self.uids)
    }
}

extension UserGroup {
    func toDTO() -> GroupDTO {
        return GroupDTO(id: self.id, uids: self.uids)
    }
}
