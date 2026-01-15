//
//  DataLayerErrors.swift
//  TodoMateData
//
//  Created by agent on 1/15/26.
//

import Foundation

/// Data 계층 인증 관련 에러
public enum AuthServiceError: Error {
  case noActiveWindowScene
  case userTokenNotFound
}

/// Data 계층 Firestore Repository 에러
public enum FirestoreRepositoryError: Error {
  case snapshotNotFound
  case decodingError(documentID: String)
  case unknownChangeType
}
