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
    var lastModifiedUser: String
    var date: Date
    var fid: String?
    var isImage: Bool
    
    init(content: String = "", lastModifiedUser: String, date: Date = .now, fid: String? = nil, isImage: Bool = false) {
        self.content = content
        self.lastModifiedUser = lastModifiedUser
        self.date = date
        self.fid = fid
        self.isImage = isImage
    }
}

extension Chat {
    static var stub: [Chat] {
        [.init(content: "안녕하세요1", lastModifiedUser: "hs", fid: "firebase1"),
         .init(content: "오늘도 반갑습니다2", lastModifiedUser: "hs", fid: "firebase2"),
         .init(content: "내일은 올까요3", lastModifiedUser: "hs", fid: "firebase3")]
    }
}
