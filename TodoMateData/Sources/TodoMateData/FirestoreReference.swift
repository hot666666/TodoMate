//
//  FirestoreReference.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import FirebaseFirestore

public final class FirestoreReference: @unchecked Sendable {
  // MainActor에서만 설정 가능하도록 제한
  @MainActor private static var _instance: FirestoreReference?

  @MainActor
  public static var shared: FirestoreReference {
    guard let instance = _instance else {
      fatalError("FirestoreReference.shared가 초기화되지 않았습니다. configure()를 먼저 호출하세요.")
    }
    return instance
  }

  @MainActor
  public static func configure(mode: FirestoreMode = .production) {
    guard _instance == nil else { return }
    _instance = (mode == .production) ? FirestoreReference() : FirestoreReference(emulator: ())
  }

  public let db: Firestore
  public let mode: FirestoreMode

  /// Production 모드로 초기화 (앱 타겟에서 사용)
  /// - 앱 시작 시 `FirebaseApp.configure()` 호출 후 사용
  private init() {
    db = Firestore.firestore()
    mode = .production
  }

  /// Emulator 모드로 초기화 (테스트에서 사용)
  /// - `FirebaseEmulatorConfigurator.configure()` 호출 후 사용
  private init(emulator _: Void) {
    db = Firestore.firestore()
    mode = .emulator
  }

  public func userCollection() -> CollectionReference {
    db.collection(DocumentCollection.USER)
  }

  public func todoCollection() -> CollectionReference {
    db.collection(DocumentCollection.TODO)
  }

  public func messageCollection() -> CollectionReference {
    db.collection(DocumentCollection.MESSAGE)
  }

  public func memoCollection() -> CollectionReference {
    db.collection(DocumentCollection.MEMO)
  }

  public func groupCollection() -> CollectionReference {
    db.collection(DocumentCollection.GROUP)
  }

  /// Firestore 로컬 캐시 삭제 (로그아웃 시 호출)
  @MainActor
  public func clearPersistence() async throws {
    do {
      try await db.clearPersistence()
    } catch {
      throw FirestoreRepositoryError.networkOperationFailed(underlying: error)
    }
  }

  /// Firestore gRPC 연결 종료 (앱 종료 시 호출)
  @MainActor
  public func terminate() async throws {
    do {
      try await db.terminate()
    } catch {
      throw FirestoreRepositoryError.networkOperationFailed(underlying: error)
    }
  }

  /// 테스트용: 모든 컬렉션의 문서 삭제
  /// - Emulator 모드에서만 사용 가능
  public func resetAllCollections() async throws {
    guard mode == .emulator else {
      fatalError("resetAllCollections는 에뮬레이터 모드에서만 사용 가능합니다.")
    }

    let collections = [
      DocumentCollection.USER,
      DocumentCollection.TODO,
      DocumentCollection.MESSAGE,
      DocumentCollection.MEMO,
      DocumentCollection.GROUP,
    ]

    for collectionName in collections {
      do {
        let snapshot = try await db.collection(collectionName).getDocuments()
        for document in snapshot.documents {
          try await document.reference.delete()
        }
      } catch {
        throw FirestoreRepositoryError.deleteFailed(underlying: error)
      }
    }
  }
}

public extension FirestoreReference {
  enum DocumentCollection {
    static let VERSION = "v2"
    static let USER = "\(VERSION)-users"
    static let TODO = "\(VERSION)-todos"
    static let MESSAGE = "\(VERSION)-group_messages"
    static let MEMO = "\(VERSION)-memos"
    static let GROUP = "\(VERSION)-groups"
  }

  /// Firestore 연결 모드
  enum FirestoreMode: Sendable {
    case production // 실제 Firebase 서버 (Dev/Prod)
    case emulator // 로컬 에뮬레이터 (테스트용)
  }
}
