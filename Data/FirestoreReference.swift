//
//  FirestoreReference.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

import FirebaseFirestore

final class FirestoreReference {
  static let shared = FirestoreReference()
  let db: Firestore

  private init() {
    db = Firestore.firestore()
    #if USE_FIREBASE_EMULATOR
      let settings = db.settings
      settings.host = "127.0.0.1:8080"
      settings.cacheSettings = MemoryCacheSettings()
      settings.isSSLEnabled = false
      db.settings = settings
      db.useEmulator(withHost: "localhost", port: 8080)
    #endif
  }

  func userCollection() -> CollectionReference {
    db.collection(FireStore.USER)
  }

  func todoCollection() -> CollectionReference {
    db.collection(FireStore.TODO)
  }

  func messageCollection() -> CollectionReference {
    db.collection(FireStore.MESSAGE)
  }

  func memoCollection() -> CollectionReference {
    db.collection(FireStore.MEMO)
  }

  #if USE_FIREBASE_EMULATOR
    /// 테스트용: 모든 컬렉션의 문서 삭제
    func resetAllCollections() async throws {
      let collections = [
        FireStore.USER,
        FireStore.TODO,
        FireStore.MESSAGE,
        FireStore.MEMO,
      ]

      for collectionName in collections {
        let snapshot = try await db.collection(collectionName).getDocuments()
        for document in snapshot.documents {
          try await document.reference.delete()
        }
      }
    }
  #endif
}
