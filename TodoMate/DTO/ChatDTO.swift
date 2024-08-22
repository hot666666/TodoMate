//
//  ChatDTO.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import FirebaseFirestore
import Foundation

struct ChatDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var sign: String
}

extension ChatDTO {
    func toModel() -> Chat {
        return Chat(content: self.content, sign: self.sign, fid: self.id!)
    }
}

extension Chat {
    func toDTO() -> ChatDTO {
        return ChatDTO(id: self.fid, content: self.content, sign: self.sign)
    }
}
