//
//  FirestoreReference.swift
//  TodoMate
//
//  Created by hs on 8/15/24.
//

#if PREVIEW
final class FirestoreReference {
	static let shared = FirestoreReference()
	let db = StubFirestore()
	
	init() {}
}
#else
import FirebaseFirestore
final class FirestoreReference {
	static let shared = FirestoreReference()
	let db: Firestore
	
	private init() {
		self.db = Firestore.firestore()
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
#endif
