//  FirebaseConfigurator.swift
//  TodoMate
//
//  Created by hs on 3/13/25.
//

import FirebaseCore
#if !PREVIEW
import FirebaseFirestore
#endif

struct FirebaseConfigurator {
	static func configure() {
		FirebaseApp.configure()
		
#if DEBUG
		let firestore = Firestore.firestore()
		let settings = firestore.settings
		settings.host = "127.0.0.1:8080"
		settings.isSSLEnabled = false
		settings.isPersistenceEnabled = false /// 디버깅 앱에서 캐시 비활성화
		firestore.settings = settings
		firestore.useEmulator(withHost: "localhost", port: 8080)
#endif
	}

}
