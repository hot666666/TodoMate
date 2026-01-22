//
//  RefreshWidgetIntent.swift
//  TodoMateWidget
//
//  AppIntent for manually refreshing widget timeline.
//
//  Created by hs on 1/22/26.
//

import AppIntents
import WidgetKit

/// AppIntent to refresh the widget timeline
struct RefreshWidgetIntent: AppIntent {
  static var title: LocalizedStringResource = "위젯 새로고침"
  static var description = IntentDescription("위젯 데이터를 최신 상태로 갱신합니다")

  func perform() async throws -> some IntentResult {
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}
