//
//  Const.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import Foundation

enum Const {}

extension Const {
  enum FireStore {
    static let VERSION = "v2"
    static let USER = "\(VERSION)-users"
    static let TODO = "\(VERSION)-todos"
    static let MESSAGE = "\(VERSION)-group_messages"
    static let MEMO = "\(VERSION)-memos"
    static let GROUP = "\(VERSION)-groups"
  }
}

typealias FireStore = Const.FireStore
