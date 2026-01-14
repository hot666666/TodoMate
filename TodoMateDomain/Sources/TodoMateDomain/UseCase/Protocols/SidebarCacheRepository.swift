//
//  SidebarCacheRepository.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

public protocol SidebarCacheRepository {
  func saveProfileName(_ name: String)
  func saveGroup(name: String, id: String)
  func clearGroupCache()
  func clearCache()
}
