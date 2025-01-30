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
    var lastModifiedUser: String
    var date: Date
    var isImage: Bool
}
#else
import FirebaseFirestore

struct ChatDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var lastModifiedUser: String
    var date: Date
    var isImage: Bool
}
#endif

extension ChatDTO {
    static let stub: [ChatDTO] = [.init(id: "1", content: "안녕하세요1", lastModifiedUser: "hs", date: .now, isImage: false),
                                  .init(id: "2", content: "안녕하세요2", lastModifiedUser: "hs", date: .now, isImage: false),
                                  .init(id: "3", content: "안녕하세요3", lastModifiedUser: "hs", date: .now, isImage: false),
                                  .init(id: "4", content: "안녕하세요4", lastModifiedUser: "hs", date: .now, isImage: false),
                                  .init(id: "5", content: "안녕하세요5", lastModifiedUser: "hs", date: .now, isImage: false)]
    
    func toModel() -> Chat {
        return Chat(content: self.content, lastModifiedUser: self.lastModifiedUser, date: self.date, fid: self.id ?? "", isImage: self.isImage)
    }
}

extension Chat {
    func toDTO() -> ChatDTO {
        return ChatDTO(id: self.fid, content: self.content, lastModifiedUser: self.lastModifiedUser, date: self.date, isImage: self.isImage)
    }
}
