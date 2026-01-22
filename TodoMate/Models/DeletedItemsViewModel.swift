//
//  DeletedItemsViewModel.swift
//  TodoMate
//
//  Created by agent on 1/22/26.
//

import Foundation
import TodoMateDomain

/// ViewModel for the Deleted Items view.
/// Manages fetching, sorting, selection, restoration, and permanent deletion.
/// Lifecycle is tied to the DeletedItemsView - created when view appears.
@Observable
@MainActor
final class DeletedItemsViewModel {
  // MARK: - Dependencies

  private let fetchUseCase: FetchDeletedItemsUseCase
  private let restoreUseCase: RestoreDeletedItemUseCase
  private let deleteUseCase: PermanentlyDeleteItemUseCase

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
    fetchUseCase: FetchDeletedItemsUseCase,
    restoreUseCase: RestoreDeletedItemUseCase,
    deleteUseCase: PermanentlyDeleteItemUseCase,
  ) {
    self.fetchUseCase = fetchUseCase
    self.restoreUseCase = restoreUseCase
    self.deleteUseCase = deleteUseCase
  }

  convenience init(container: CoreDIContainer) {
    self.init(
      fetchUseCase: container.fetchDeletedItemsUseCase,
      restoreUseCase: container.restoreDeletedItemUseCase,
      deleteUseCase: container.permanentlyDeleteItemUseCase,
    )
  }

  // MARK: - Actions

  func fetch() async {
    isLoading = true
    error = nil

    do {
      items = try await fetchUseCase.run()
      selectedIds.formIntersection(items.map(\.id))
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
      try await restoreUseCase.run(itemsToRestore)
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
      try await deleteUseCase.run(itemsToDelete)
      selectedIds.removeAll()
      await fetch()
    } catch {
      self.error = error
    }
  }

  func emptyTrash() async {
    do {
      try await deleteUseCase.runAll()
      selectedIds.removeAll()
      items.removeAll()
    } catch {
      self.error = error
    }
  }
}

// MARK: - Preview Support

extension DeletedItemsViewModel {
  static var preview: DeletedItemsViewModel {
    DeletedItemsViewModel(
      fetchUseCase: StubFetchDeletedItemsUseCase(),
      restoreUseCase: StubRestoreDeletedItemUseCase(),
      deleteUseCase: StubPermanentlyDeleteItemUseCase(),
    )
  }
}
