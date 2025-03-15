//
//  TodoTransferData.swift
//  TodoMate
//
//  Created by hs on 8/26/24.
//

import SwiftUI

struct TodoTransferData: Codable, Transferable {
  let fid: String
  let date: Date

  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .todo)
  }
}

extension Todo: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: { todo in
      TodoTransferData(fid: todo.fid, date: todo.date)
    })
  }
}
