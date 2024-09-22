//
//  TodoTransferData.swift
//  TodoMate
//
//  Created by hs on 8/26/24.
//

import SwiftUI

struct TodoTransferData: Codable, Transferable {
    let id: String
    let date: Date
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .todo)
    }
}

extension Todo: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: { todo in
            TodoTransferData(id: todo.id, date: todo.date)
        })
    }
}
