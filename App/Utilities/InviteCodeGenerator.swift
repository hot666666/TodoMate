//
//  InviteCodeGenerator.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import Foundation

protocol InviteCodeGeneratorProtocol {
  func generate() -> String
}

struct InviteCodeGenerator: InviteCodeGeneratorProtocol {
  func generate() -> String {
    let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return String((0 ..< 6).compactMap { _ in characters.randomElement() })
  }
}
