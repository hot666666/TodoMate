//
//  Chat.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import SwiftUI

@Observable
class Chat: Identifiable {
    let id: String = UUID().uuidString
    var content: String
    var sign: String
    var fid: String?
    
    init(content: String = "", sign: String = UUID().uuidString, fid: String? = nil) {
        self.content = content
        self.sign = sign
        self.fid = fid
    }
}

extension Chat {
    func toDTO() -> ChatDTO {
        return ChatDTO(id: self.fid, content: self.content, sign: self.sign)
    }
}
