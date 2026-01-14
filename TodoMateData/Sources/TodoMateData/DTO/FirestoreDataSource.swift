//
//  FirestoreDataSource.swift
//  Todo
//
//  Created by hs on 7/7/25.
//

import FirebaseFirestore
import TodoMateDomain

public extension DataSource {
  /// Firebase FirestoreSource로 변환
  var firestoreSource: FirestoreSource {
    switch self {
    case .server:
      .server
    case .cache:
      .cache
    case .default:
      .default
    }
  }
}
