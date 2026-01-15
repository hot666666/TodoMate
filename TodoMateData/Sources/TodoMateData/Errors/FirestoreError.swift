//
//  FirestoreError.swift
//  TodoMateData
//
//  Created by agent on 1/15/26.
//

import Foundation

/// Data 계층 Firestore Repository 에러
public enum FirestoreRepositoryError: Error {
  // Observation 관련
  case snapshotNotFound
  case decodingError(documentID: String)
  case unknownChangeType

  // CRUD 작업 관련
  case createFailed(underlying: Error)
  case readFailed(underlying: Error)
  case updateFailed(underlying: Error)
  case deleteFailed(underlying: Error)
  case transactionFailed(underlying: Error)
  case networkOperationFailed(underlying: Error)
}
