//
//  DeletedItemsStore.swift
//  TodoMate
//
//  Created by agent on 1/22/26.
//

import Foundation
import TodoMateDomain

/// Manages state for the Deleted Items sidebar view.
/// Handles fetching, sorting, selection, restoration, and permanent deletion of deleted items.
@Observable
@MainActor
final class DeletedItemsStore {
  // MARK: - Dependencies

  private let fetchDeletedItemsUseCase: FetchDeletedItemsUseCase
  private let restoreDeletedItemUseCase: RestoreDeletedItemUseCase
  private let permanentlyDeleteItemUseCase: PermanentlyDeleteItemUseCase

  // MARK: - State

  private(set) var items: [DeletedItem] = []
  private(set) var isLoading = false
  private(set) var error: Error?

  var selectedIds: Set<String> = []
  var sortOrder: SortOrder = .newestFirst

  enum SortOrder: String, CaseIterable {
    case newestFirst = "최근 삭제순"
    case oldestFirst = "오래된순"
  }

  // MARK: - Computed Properties

  var sortedItems: [DeletedItem] {
    switch sortOrder {
    case .newestFirst:
      items.sorted { $0.deletedAt > $1.deletedAt }
    case .oldestFirst:
      items.sorted { $0.deletedAt < $1.deletedAt }
    }
  }

  var selectedItems: [DeletedItem] {
    items.filter { selectedIds.contains($0.id) }
  }

  var hasSelection: Bool {
    !selectedIds.isEmpty
  }

  var isAllSelected: Bool {
    !items.isEmpty && selectedIds.count == items.count
  }

  // MARK: - Init

  init(
    fetchDeletedItemsUseCase: FetchDeletedItemsUseCase,
    restoreDeletedItemUseCase: RestoreDeletedItemUseCase,
    permanentlyDeleteItemUseCase: PermanentlyDeleteItemUseCase,
  ) {
    self.fetchDeletedItemsUseCase = fetchDeletedItemsUseCase
    self.restoreDeletedItemUseCase = restoreDeletedItemUseCase
    self.permanentlyDeleteItemUseCase = permanentlyDeleteItemUseCase
  }

  // MARK: - Actions

  func fetch() async {
    isLoading = true
    error = nil

    do {
      items = try await fetchDeletedItemsUseCase.run()
      // Remove selected IDs that no longer exist
      selectedIds = selectedIds.filter { id in items.contains { $0.id == id } }
    } catch {
      self.error = error
    }

    isLoading = false
  }

  func toggleSelection(for item: DeletedItem) {
    if selectedIds.contains(item.id) {
      selectedIds.remove(item.id)
    } else {
      selectedIds.insert(item.id)
    }
  }

  func selectAll() {
    selectedIds = Set(items.map(\.id))
  }

  func deselectAll() {
    selectedIds.removeAll()
  }

  func restoreSelected() async {
    let itemsToRestore = selectedItems
    guard !itemsToRestore.isEmpty else { return }

    do {
      try await restoreDeletedItemUseCase.run(itemsToRestore)
      selectedIds.removeAll()
      await fetch()
    } catch {
      self.error = error
    }
  }

  func permanentlyDeleteSelected() async {
    let itemsToDelete = selectedItems
    guard !itemsToDelete.isEmpty else { return }

    do {
      try await permanentlyDeleteItemUseCase.run(itemsToDelete)
      selectedIds.removeAll()
      await fetch()
    } catch {
      self.error = error
    }
  }

  func emptyTrash() async {
    do {
      try await permanentlyDeleteItemUseCase.runAll()
      selectedIds.removeAll()
      items.removeAll()
    } catch {
      self.error = error
    }
  }
}

// MARK: - Preview Support

extension DeletedItemsStore {
  static var preview: DeletedItemsStore {
    DeletedItemsStore(
      fetchDeletedItemsUseCase: StubFetchDeletedItemsUseCase(),
      restoreDeletedItemUseCase: StubRestoreDeletedItemUseCase(),
      permanentlyDeleteItemUseCase: StubPermanentlyDeleteItemUseCase(),
    )
  }
}
