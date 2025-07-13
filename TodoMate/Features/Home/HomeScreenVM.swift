//
//  HomeScreenVM.swift
//  Todo
//
//  Created by hs on 7/9/25.
//

import SwiftUI

@Observable
final class HomeScreenVM {
  @AppStorage("userSelection.showDropdown") @ObservationIgnored private var _persistedShowDropdown: Bool = false
  private var _showDropdownCache: Bool?

  // MARK: - Properties

  var showDropdown: Bool {
    get {
      // 캐시된 값이 있으면 사용, 없으면 영구 저장소에서 로드하여 캐싱
      if let cached = _showDropdownCache {
        return cached
      }
      let value = _persistedShowDropdown
      _showDropdownCache = value
      return value
    }
    set {
      // 캐시와 영구 저장소 모두 업데이트
      _showDropdownCache = newValue
      _persistedShowDropdown = newValue
    }
  }

  var selectedUserId: String = ""

  var isEditingMemo: Bool = false
}
