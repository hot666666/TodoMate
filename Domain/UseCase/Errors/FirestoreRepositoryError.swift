//
//  FirestoreRepositoryError.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import Foundation

enum FirestoreRepositoryError: Error {
  case decodingError(documentID: String)
  case snapshotNotFound
  case unknownChangeType
}
