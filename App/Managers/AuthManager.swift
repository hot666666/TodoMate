//
//  AuthManager.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseAuth
import FirebaseFirestore

@MainActor
@Observable
final class AuthManager {
  private var authHandle: AuthStateDidChangeListenerHandle?
  private let db = Firestore.firestore()

  private(set) var firebaseUser: FirebaseAuth.User?
  private(set) var currentUser: User?

  var isAuthenticated: Bool { firebaseUser != nil }
  var isAnonymous: Bool { firebaseUser?.isAnonymous ?? true }

  init() {}

  func startListening() {
    authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      Task { @MainActor in
        self?.firebaseUser = user
        if let uid = user?.uid {
          await self?.fetchUser(uid: uid)
        } else {
          self?.currentUser = nil
        }
      }
    }
  }

  /// 앱 시작 시 익명 로그인
  func signInAnonymously() async throws {
    let result = try await Auth.auth().signInAnonymously()
    let user = User(id: result.user.uid)
    try db.collection("users").document(result.user.uid).setData(from: user)
    currentUser = user
  }

  /// 소셜 계정 연동 (익명 → 정식 유저)
  func linkWithCredential(_ credential: AuthCredential) async throws {
    guard let firebaseUser else { return }
    let result = try await firebaseUser.link(with: credential)

    // 이메일/이름만 업데이트 (authorized는 유지 - 명시적 Merge 버튼 필요)
    try await db.collection("users").document(result.user.uid).updateData([
      "email": result.user.email ?? "",
      "displayName": result.user.displayName ?? "User",
      "updatedAt": FieldValue.serverTimestamp(),
    ])

    await fetchUser(uid: result.user.uid)
  }

  /// 로그아웃 (로컬 캐시만 삭제)
  func signOut() async throws {
    try Auth.auth().signOut()
    try await Firestore.firestore().clearPersistence()
    currentUser = nil
  }

  private func fetchUser(uid: String) async {
    do {
      let doc = try await db.collection("users").document(uid).getDocument()
      currentUser = try doc.data(as: User.self)
    } catch {
      print("[AuthManager] fetchUser error: \(error)")
      currentUser = nil
    }
  }
}
