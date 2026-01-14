//
//  SidebarCacheUseCase.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

public protocol SidebarCacheUseCase {
  func saveProfileName(_ name: String)
  func saveGroup(name: String, id: String)
  func clearGroupCache()
  func clearCache()
}

public final class SidebarCacheUseCaseImpl: SidebarCacheUseCase {
  private let repository: SidebarCacheRepository

  public init(repository: SidebarCacheRepository) {
    self.repository = repository
  }

  public func saveProfileName(_ name: String) {
    repository.saveProfileName(name)
  }

  public func saveGroup(name: String, id: String) {
    repository.saveGroup(name: name, id: id)
  }

  public func clearGroupCache() {
    repository.clearGroupCache()
  }

  public func clearCache() {
    repository.clearCache()
  }
}
