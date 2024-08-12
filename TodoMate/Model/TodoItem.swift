//
//  TodoItem.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

@Observable
class TodoItem: Identifiable {
    enum Status: String, CaseIterable {
        case todo = "시작 전"
        case inProgress = "진행 중"
        case complete = "완료"
        case inComplete = "미완료"
        
        var color: Color {
            switch self {
            case .todo: return .gray
            case .inProgress: return .blue
            case .complete: return .green
            case .inComplete: return .red
            }
        }
    }
    
    var id: String
    var date: Date
    var content: String
    var status: Status
    var detail: String
    var startTime: Date?
    var endTime: Date?
    
    init(){
        self.id = UUID().uuidString
        self.date = .now
        self.content = "이름없음"
        self.status = .todo
        self.detail = ""
    }
    
    init(id: String, date: Date, content: String, detail: String = "", status: Status, startTime: Date? = nil, endTime: Date? = nil) {
        self.id = id
        self.date = date
        self.content = content
        self.detail = detail
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
    }
}


extension TodoItem {
    static var stub: [TodoItem] {
        [.init(id: UUID().uuidString, date: .now, content: "할 일1", status: .todo),
         .init(id: UUID().uuidString, date: .now, content: "할 일2", status: .todo),
         .init(id: UUID().uuidString, date: .now, content: "할 일3", status: .todo)]
    }
}
