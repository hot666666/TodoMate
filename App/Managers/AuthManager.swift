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
  private let db: Firestore

  private(set) var firebaseUser: FirebaseAuth.User?
  private(set) var currentUser: User?

  var isAuthenticated: Bool { firebaseUser != nil }
  var isAnonymous: Bool { firebaseUser?.isAnonymous ?? true }

  init(db: Firestore) {
    self.db = db
  }

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

  /// 익명 로그인 (수동 호출)
  func signInAnonymously() async throws {
    let result = try await Auth.auth().signInAnonymously()
    let user = User(id: result.user.uid)

    do {
      try db.collection("users").document(result.user.uid).setData(from: user)
      currentUser = user
      Log.info("Anonymous sign in successful: \(result.user.uid)", category: .auth)
    } catch {
      // Firestore 사용자 문서 생성 실패 시, 생성된 익명 계정을 정리하여 상태 불일치를 방지
      Log.error(
        "Failed to create user document, deleting anonymous user: \(error)", category: .auth,
      )
      do {
        try await result.user.delete()
      } catch {
        Log.error(
          "Failed to delete anonymous user after Firestore error: \(error)", category: .auth,
        )
      }
      throw error
    }
  }

  /// 소셜 계정 연동 (익명 → 정식 유저)
  /// 주의: authorized는 자동으로 true가 되지 않음.
  func linkWithCredential(_ credential: AuthCredential) async throws {
    guard let firebaseUser else { return }

    do {
      let result = try await firebaseUser.link(with: credential)

      do {
        try await db.collection("users").document(result.user.uid).updateData([
          "email": result.user.email ?? "",
          "displayName": result.user.displayName ?? "User",
          "updatedAt": FieldValue.serverTimestamp(),
        ])
        await fetchUser(uid: result.user.uid)
        Log.info("Linked credential for user: \(result.user.uid)", category: .auth)
      } catch {
        // Firestore 업데이트 실패 시, 연동을 롤백 시도
        Log.error("Firestore update failed, unlinking provider: \(error)", category: .auth)
        do {
          try await result.user.unlink(fromProvider: credential.provider)
        } catch {
          Log.error("Failed to unlink provider after Firestore error: \(error)", category: .auth)
        }
        throw error
      }
    } catch {
      Log.error("linkWithCredential error: \(error)", category: .auth)
      throw error
    }
  }

  /// 로그아웃 (Firebase Auth 로그아웃 + Firestore 로컬 캐시 삭제)
  func signOut() async throws {
    try Auth.auth().signOut()
    try await db.clearPersistence()
    currentUser = nil
    Log.info("User signed out and persistence cleared", category: .auth)
  }

  private func fetchUser(uid: String) async {
    do {
      let doc = try await db.collection("users").document(uid).getDocument()

      guard doc.exists else {
        Log.warning("User document not found for uid=\(uid)", category: .auth)
        currentUser = nil
        return
      }

      currentUser = try doc.data(as: User.self)
    } catch let decodingError as DecodingError {
      Log.error("fetchUser decoding error for uid=\(uid): \(decodingError)", category: .auth)
      currentUser = nil
    } catch let nsError as NSError {
      Log.error(
        "fetchUser Firestore error for uid=\(uid): domain=\(nsError.domain), code=\(nsError.code)",
        category: .auth,
      )
      currentUser = nil
    } catch {
      Log.error("fetchUser unexpected error for uid=\(uid): \(error)", category: .auth)
      currentUser = nil
    }
  }
}
