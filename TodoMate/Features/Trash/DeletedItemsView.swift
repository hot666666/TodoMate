//
//  DeletedItemsView.swift
//  TodoMate
//
//  Created by agent on 1/22/26.
//

import SimpleOverlaySystem
import SwiftUI
import TodoMateDomain

/// Main view for displaying and managing deleted items (trash).
/// Supports multi-selection, sorting, restoration, and permanent deletion.
/// Uses ViewModel pattern - viewModel is created when view appears.
struct DeletedItemsView: View {
  // MARK: - Environment

  @Environment(\.overlayManager) private var overlay

  // MARK: - State

  @State private var viewModel: DeletedItemsViewModel

  init(container: CoreDIContainer) {
    _viewModel = State(initialValue: DeletedItemsViewModel(container: container))
  }

  // MARK: - Body

  var body: some View {
    contentView
      .toolbar {
        toolbarContent
      }
      .task {
        await viewModel.fetch()
      }
      .navigationTitle("삭제된 항목")
      .accessibilityIdentifier("deletedItemsView")
  }

  private var emptyView: some View {
    ContentUnavailableView(
      "휴지통이 비어있습니다",
      systemImage: "trash",
      description: Text("삭제된 Todo와 Memo가 여기에 표시됩니다."),
    )
    .opacity(0.6)
  }

  @ViewBuilder
  private var contentView: some View {
    Group {
      if viewModel.isLoading {
        ProgressView()
      } else if viewModel.items.isEmpty {
        emptyView
      } else {
        listView
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private var listView: some View {
    List(viewModel.sortedItems, selection: Bindable(viewModel).selectedIds) { item in
      DeletedItemRow(item: item, isSelected: viewModel.selectedIds.contains(item.id))
        .tag(item.id)
        .contentShape(.rect)
        .onTapGesture {
          viewModel.toggleSelection(for: item)
        }
    }
    .listStyle(.inset)
    .scrollContentBackground(.hidden)
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      selectAllButton
    }
    ToolbarSpacer(.flexible)
    if viewModel.hasSelection {
      ToolbarItem(placement: .primaryAction) {
        restoreButton
      }
      ToolbarItem(placement: .primaryAction) {
        deleteButton
      }
      ToolbarSpacer(.flexible)
    }
    ToolbarItem(placement: .primaryAction) {
      sortMenu
    }
  }

  private var sortMenu: some View {
    Menu {
      ForEach(DeletedItemsViewModel.SortOrder.allCases, id: \.self) { order in
        Button {
          viewModel.sortOrder = order
        } label: {
          if viewModel.sortOrder == order {
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
      if viewModel.isAllSelected {
        viewModel.deselectAll()
      } else {
        viewModel.selectAll()
      }
    } label: {
      Label(
        viewModel.isAllSelected ? "선택 해제" : "전체 선택",
        systemImage: viewModel.isAllSelected ? "checkmark.circle.fill" : "checkmark.circle",
      )
    }
    .disabled(viewModel.items.isEmpty)
  }

  private var restoreButton: some View {
    Button {
      showRestoreConfirmation()
    } label: {
      Label("복구", systemImage: "arrow.uturn.backward")
    }
    .help("선택한 항목 복구")
  }

  private var deleteButton: some View {
    Button(role: .destructive) {
      showDeleteConfirmation()
    } label: {
      Label("영구 삭제", systemImage: "trash")
    }
    .help("선택한 항목 영구 삭제")
  }

  /// Shows a confirmation overlay for restore action
  private func showRestoreConfirmation() {
    showConfirmation(
      title: "복구",
      message: "선택한 \(viewModel.selectedIds.count)개 항목을 복구하시겠습니까?",
      actionTitle: "복구",
      isDestructive: false,
    ) {
      Task {
        await viewModel.restoreSelected()
        overlay?.dismissTop()
      }
    }
  }

  /// Shows a confirmation overlay for permanent delete action
  private func showDeleteConfirmation() {
    showConfirmation(
      title: "영구 삭제",
      message: "선택한 \(viewModel.selectedIds.count)개 항목을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
      actionTitle: "삭제",
      isDestructive: true,
    ) {
      Task {
        await viewModel.permanentlyDeleteSelected()
        overlay?.dismissTop()
      }
    }
  }

  /// Generic confirmation overlay presenter
  private func showConfirmation(
    title: String,
    message: String,
    actionTitle: String,
    isDestructive: Bool,
    action: @escaping () -> Void,
  ) {
    overlay?.presentCentered(id: OverlayIDs.confirmation, backdropOpacity: 0) {
      ConfirmationView(
        title: title,
        message: message,
        destructiveActionTitle: actionTitle,
        cancelTitle: "취소",
        isDestructive: isDestructive,
        destructiveAction: action,
        onDismiss: {
          overlay?.dismissTop()
        },
      )
    }
  }
}

// MARK: - Preview

#Preview {
  NavigationStack {
    DeletedItemsView(container: .preview)
  }
}
