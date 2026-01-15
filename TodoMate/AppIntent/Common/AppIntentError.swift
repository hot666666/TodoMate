//
//  AppIntentError.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation

enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
  case containerNotFound
  case todoNotFound(id: String)
  case memoNotFound(id: String)
  case unknown

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .containerNotFound:
      "앱 서비스를 사용할 수 없습니다."
    case let .todoNotFound(id):
      "ID가 \(id)인 할 일을 찾을 수 없습니다."
    case let .memoNotFound(id):
      "ID가 \(id)인 메모를 찾을 수 없습니다."
    case .unknown:
      "알 수 없는 오류가 발생했습니다."
    }
  }
}
