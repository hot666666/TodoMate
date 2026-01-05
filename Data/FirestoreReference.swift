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
