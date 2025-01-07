//
//  ChatDTO.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation

#if PREVIEW
struct ChatDTO {
    var id: String?
    var content: String
    var sign: String
    var date: Date
    var isImage: Bool
}
#else
import FirebaseFirestore

struct ChatDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var sign: String
    var date: Date
    var isImage: Bool
}
#endif

extension ChatDTO {
    func toModel() -> Chat {
        return Chat(content: self.content, sign: self.sign, date: self.date, fid: self.id!, isImage: self.isImage)
    }
}

extension Chat {
    func toDTO() -> ChatDTO {
        return ChatDTO(id: self.fid, content: self.content, sign: self.sign, date: self.date, isImage: self.isImage)
    }
}
