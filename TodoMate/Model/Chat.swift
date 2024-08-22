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
    static var stub: [Chat] {
        [.init(content: "챗1"), .init(content: "챗2"), .init(content: "챗3")]
    }
}
