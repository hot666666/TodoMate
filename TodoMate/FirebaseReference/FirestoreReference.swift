//
//  FireStoreReference.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

import Firebase

#if !PREVIEW
import FirebaseFirestore
final class FirestoreReference {
    static let shared = FirestoreReference()
    let db = Firestore.firestore()
    
    private init() {}
    
    func userCollection() -> CollectionReference {
        return db.collection(FireStore.USER)
    }
    
    func todoCollection() -> CollectionReference {
        return db.collection(FireStore.TODO)
    }
    
    func chatCollection() -> CollectionReference {
        return db.collection(FireStore.CHAT)
    }
    
    func groupCollection() -> CollectionReference {
        return db.collection(FireStore.GROUP)
    }
}
#else
class FirestoreReference {
    static let shared = FirestoreReference()
    
    private init() {}
}
#endif
