//
//  DeletedItemsView.swift
//  TodoMate
//
//  Created by agent on 1/22/26.
//

import SwiftUI
import TodoMateDomain

/// Main view for displaying and managing deleted items (trash).
/// Supports multi-selection, sorting, restoration, and permanent deletion.
struct DeletedItemsView: View {
  // MARK: - Dependencies

  @Environment(DeletedItemsStore.self) private var store

  // MARK: - State

  @State private var showDeleteConfirmation = false

  // MARK: - Body

  var body: some View {
    @Bindable var store = store

    Group {
      if store.isLoading, store.items.isEmpty {
        loadingView
      } else if store.items.isEmpty {
        emptyView
      } else {
        itemsList
      }
    }
    .navigationTitle("삭제된 항목")
    .toolbar {
      toolbarContent
    }
    .task {
      await store.fetch()
    }
    .confirmationDialog(
      "영구 삭제",
      isPresented: $showDeleteConfirmation,
      titleVisibility: .visible,
    ) {
      Button("삭제", role: .destructive) {
        Task {
          await store.permanentlyDeleteSelected()
        }
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text("선택한 \(store.selectedIds.count)개 항목을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
    }
    .accessibilityIdentifier("deletedItemsView")
  }

  // MARK: - Subviews

  private var loadingView: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyView: some View {
    ContentUnavailableView(
      "휴지통이 비어있습니다",
      systemImage: "trash",
      description: Text("삭제된 Todo와 Memo가 여기에 표시됩니다."),
    )
  }

  private var itemsList: some View {
    List(store.sortedItems, selection: Bindable(store).selectedIds) { item in
      DeletedItemRow(item: item, isSelected: store.selectedIds.contains(item.id))
        .tag(item.id)
        .contentShape(.rect)
        .onTapGesture {
          store.toggleSelection(for: item)
        }
    }
    .listStyle(.inset)
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      sortMenu
      selectAllButton
    }

    ToolbarItemGroup(placement: .secondaryAction) {
      if store.hasSelection {
        restoreButton
        deleteButton
      }
    }
  }

  private var sortMenu: some View {
    Menu {
      ForEach(DeletedItemsStore.SortOrder.allCases, id: \.self) { order in
        Button {
          store.sortOrder = order
        } label: {
          if store.sortOrder == order {
            Label(order.rawValue, systemImage: "checkmark")
          } else {
            Text(order.rawValue)
          }
        }
      }
    } label: {
      Label("정렬", systemImage: "arrow.up.arrow.down")
    }
  }

  private var selectAllButton: some View {
    Button {
      if store.isAllSelected {
        store.deselectAll()
      } else {
        store.selectAll()
      }
    } label: {
      Label(
        store.isAllSelected ? "선택 해제" : "전체 선택",
        systemImage: store.isAllSelected ? "checkmark.circle.fill" : "checkmark.circle",
      )
    }
    .disabled(store.items.isEmpty)
  }

  private var restoreButton: some View {
    Button {
      Task {
        await store.restoreSelected()
      }
    } label: {
      Label("복구", systemImage: "arrow.uturn.backward")
    }
    .help("선택한 항목 복구")
  }

  private var deleteButton: some View {
    Button(role: .destructive) {
      showDeleteConfirmation = true
    } label: {
      Label("영구 삭제", systemImage: "trash")
    }
    .help("선택한 항목 영구 삭제")
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    DeletedItemsView()
      .environment(DeletedItemsStore.preview)
  }
}
