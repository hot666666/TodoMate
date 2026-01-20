//
//  MemoViewModel.swift
//  TodoMate
//
//  Created by agent on 1/15/26.
//

import Foundation
import Observation
import TodoMateDomain

@Observable
@MainActor
final class MemoViewModel {
  private let store: MemoStore

  init(store: MemoStore) {
    self.store = store
  }

  var memos: [Memo] {
    store.memos
  }

  func addMemo() {
    store.add(content: "New Memo")
  }

  func updateMemo(_ memo: Memo) {
    store.update(memo)
  }

  func deleteMemo(_ memo: Memo) {
    store.delete(memo)
  }
}

extension MemoViewModel {
  static var preview: MemoViewModel {
    MemoViewModel(store: MemoStore.preview)
  }
}
