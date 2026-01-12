//
//  SidebarCacheUseCase.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

protocol SidebarCacheUseCase {
  func saveProfileName(_ name: String)
  func saveGroup(name: String, id: String)
  func clearGroupCache()
  func clearCache()
}

final class SidebarCacheUseCaseImpl: SidebarCacheUseCase {
  private let repository: SidebarCacheRepository

  init(repository: SidebarCacheRepository) {
    self.repository = repository
  }

  func saveProfileName(_ name: String) {
    repository.saveProfileName(name)
  }

  func saveGroup(name: String, id: String) {
    repository.saveGroup(name: name, id: id)
  }

  func clearGroupCache() {
    repository.clearGroupCache()
  }

  func clearCache() {
    repository.clearCache()
  }
}
