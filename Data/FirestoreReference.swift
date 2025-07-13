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
    #if DEBUG
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
}
