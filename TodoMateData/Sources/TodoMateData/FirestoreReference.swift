//
//  FirestoreReference.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import FirebaseFirestore

/// Firestore 연결 모드
public enum FirestoreMode {
  case production // 실제 Firebase 서버 (Dev/Prod)
  case emulator // 로컬 에뮬레이터 (테스트용)
}

public final class FirestoreReference: @unchecked Sendable {
  public nonisolated(unsafe) static var shared: FirestoreReference!

  public let db: Firestore
  public let mode: FirestoreMode

  /// Production 모드로 초기화 (앱 타겟에서 사용)
  /// - 앱 시작 시 `FirebaseApp.configure()` 호출 후 사용
  public init() {
    db = Firestore.firestore()
    mode = .production
  }

  /// Emulator 모드로 초기화 (테스트에서 사용)
  /// - `FirebaseEmulatorConfigurator.configure()` 호출 후 사용
  public init(emulator _: Void) {
    db = Firestore.firestore()
    mode = .emulator
  }

  public func userCollection() -> CollectionReference {
    db.collection(FireStore.USER)
  }

  public func todoCollection() -> CollectionReference {
    db.collection(FireStore.TODO)
  }

  public func messageCollection() -> CollectionReference {
    db.collection(FireStore.MESSAGE)
  }

  public func memoCollection() -> CollectionReference {
    db.collection(FireStore.MEMO)
  }

  public func groupCollection() -> CollectionReference {
    db.collection(FireStore.GROUP)
  }

  /// 테스트용: 모든 컬렉션의 문서 삭제
  /// - Emulator 모드에서만 사용 가능
  public func resetAllCollections() async throws {
    guard mode == .emulator else {
      fatalError("resetAllCollections는 에뮬레이터 모드에서만 사용 가능합니다.")
    }

    let collections = [
      FireStore.USER,
      FireStore.TODO,
      FireStore.MESSAGE,
      FireStore.MEMO,
      FireStore.GROUP,
    ]

    for collectionName in collections {
      let snapshot = try await db.collection(collectionName).getDocuments()
      for document in snapshot.documents {
        try await document.reference.delete()
      }
    }
  }
}

public enum FireStore {
  public static let USER = "users"
  public static let TODO = "todos"
  public static let MESSAGE = "messages"
  public static let MEMO = "memos"
  public static let GROUP = "groups"
}
