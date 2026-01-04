//
//  Todo+Transferable.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static let todo = UTType(exportedAs: "io.hotcs6.TodoMate.todo")
}

extension Todo: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .todo)
  }
}
