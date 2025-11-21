//
//  AppError.swift
//  TodoMate
//
//  Created by hs on 7/21/25.
//

import Foundation

/// 앱 전역에서 사용하는 에러 타입
enum AppError: Error, Identifiable {
  case firestoreError(FirestoreRepositoryError)
  case authError(AuthServiceError)
  case networkError(Error)
  case unknownError(Error)
  case customError(String)

  var id: String {
    switch self {
    case .firestoreError: "firestore"
    case .authError: "auth"
    case .networkError: "network"
    case .unknownError: "unknown"
    case .customError: "custom"
    }
  }

  var title: String {
    switch self {
    case .firestoreError: "데이터베이스 오류"
    case .authError: "인증 오류"
    case .networkError: "네트워크 오류"
    case .unknownError: "알 수 없는 오류"
    case .customError: "오류"
    }
  }

  var message: String {
    switch self {
    case let .firestoreError(error):
      switch error {
      case let .decodingError(documentID):
        "문서(\(documentID))를 읽는 중 오류가 발생했습니다."
      case .snapshotNotFound:
        "데이터를 찾을 수 없습니다."
      case .unknownChangeType:
        "알 수 없는 변경 사항입니다."
      }
    case let .authError(error):
      switch error {
      case .noActiveWindowScene:
        "활성 창을 찾을 수 없습니다."
      case .userTokenNotFound:
        "사용자 토큰을 찾을 수 없습니다."
      case .dataConversionFailed:
        "데이터 변환에 실패했습니다."
      case let .unknownError(error):
        error?.localizedDescription ?? "알 수 없는 인증 오류가 발생했습니다."
      case let .customError(message):
        message
      }
    case let .networkError(error):
      "네트워크 오류: \(error.localizedDescription)"
    case let .unknownError(error):
      "알 수 없는 오류: \(error.localizedDescription)"
    case let .customError(message):
      message
    }
  }

  static func from(_ error: Error) -> AppError {
    if let firestoreError = error as? FirestoreRepositoryError {
      .firestoreError(firestoreError)
    } else if let authError = error as? AuthServiceError {
      .authError(authError)
    } else {
      .unknownError(error)
    }
  }
}
