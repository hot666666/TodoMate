//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum AuthError: Error {
    case invalidAppConfiguration
    case noActiveWindowScene
    case failedToGetToken
    case failedToGetUserID
}

protocol AuthManagerType {
    var authState: AuthManager.AuthState { get }
    var userInfo: AuthManager.UserInfo { get }
    func updateUserInfo(_ gid: String)
    func signIn() async
    func signOut() async
}

#if !PREVIEW
@Observable
class AuthManager: AuthManagerType {
    private let userService: UserServiceType
    private let userInfoService: UserInfoServiceType
    private let modelContainer: ModelContainer
    
    private var _userInfo: UserInfo
    
    // TODO: - 로컬에 값은 존재 하나, 서버에 유저 정보가 없는 경우 처리
    private(set) var userInfo: UserInfo {
        get { _userInfo }
        set {
            _userInfo = newValue
            userInfoService.saveUserInfo(newValue)
        }
    }
    
    private(set) var authState: AuthState = .signedOut
    
    init(container: DIContainer) {
        self.userService = container.userService
        self.userInfoService = container.userInfoService
        self.modelContainer = container.modelContainer
        
        /// 로컬에 저장된 유저 정보 불러오기
        self._userInfo = userInfoService.loadUserInfo()
        self.authState = _userInfo.id.isEmpty ? .signedOut : .signedIn
    }
    
    @MainActor
    func signIn() async {
        authState = .loading
        
        do {
            guard let clientId = FirebaseApp.app()?.options.clientID else {
                print("Error: Invalid app configuration")
                throw AuthError.invalidAppConfiguration
            }
            
            let configuration = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
#if os(macOS)
            guard let windowScene = NSApplication.shared.windows.first else {
                print("Error: No active window scene found")
                throw AuthError.noActiveWindowScene
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: windowScene)
#elseif os(iOS)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                print("Error: No active window scene found")
                throw AuthError.noActiveWindowScene
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
#endif
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("Error: Failed to get authentication token")
                throw AuthError.failedToGetToken
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            guard !user.uid.isEmpty else {
                print("Error: Failed to get user ID")
                throw AuthError.failedToGetUserID
            }
            
            let fUser = await handleUserAuthentication(uid: user.uid, name: user.displayName ?? "Unknown")
            await removeAllTodoEntity()
            userInfo = .init(id: fUser.uid, token: idToken, gid: fUser.gid)
            print("Sign in successful for user: \(userInfo.id)")
        } catch {
            authState = .signedOut
            print("Authentication failed: \(error.localizedDescription)")
            return
        }
        
        authState = .signedIn
    }
    
    @MainActor
    func signOut() async {
        authState = .loading
        
        GIDSignIn.sharedInstance.signOut()
        await removeAllTodoEntity()
        userInfo = .empty
        
        authState = .signedOut
        print("User signed out successfully")
    }
    
    // TODO: - 다른 요소에 대해서도 업데이트가 필요한 경우 추가
    func updateUserInfo(_ gid: String) {
        userInfo = .init(id: userInfo.id, token: userInfo.token, gid: gid)
    }
}
extension AuthManager {
    private func handleUserAuthentication(uid: String, name: String) async -> User {
        guard let existingUser = await userService.fetch(uid: uid) else {
            let newUser = User(uid: uid, nickname: name)
            
            await userService.update(newUser)
            print("Created new user: \(newUser.uid)")
            return newUser
        }
        
        print("User already exists with uid: \(existingUser.uid)")
        return existingUser
    }
    
    @MainActor
    private func removeAllTodoEntity() async {
        let modelContext = modelContainer.mainContext
        modelContext.container.deleteAllData()
    }
}
#else
@Observable
class AuthManager: AuthManagerType {
    var authState: AuthManager.AuthState = .signedOut
    var userInfo: AuthManager.UserInfo = .empty
    
    init(container: DIContainer) {}
    
    func updateUserInfo(_ gid: String) {
        userInfo = .init(id: userInfo.id, token: userInfo.token, gid: gid)
    }
    
    @MainActor
    func signIn() async {
        authState = .loading
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        userInfo = .init(id: User.stub[0].uid, token: UUID().uuidString, gid: "")
        print("User signed in")
        
        authState = .signedIn
    }
    
    @MainActor
    func signOut() async {
        authState = .loading
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        userInfo = .empty
        print("User signed out")
        
        authState = .signedOut
    }
}
#endif
extension AuthManager {
    enum AuthState {
        case signedOut
        case signedIn
        case loading
//        case error(String)
    }
    
    struct UserInfo: Codable {
        let id: String
        let token: String
        let gid: String
        
        static let empty = UserInfo(id: "", token: "", gid: "")
        static let stub = UserInfo(id: User.stub[0].uid, token: UUID().uuidString, gid: "")
        static let hasGroupStub = UserInfo(id: User.stub[0].uid, token: UUID().uuidString, gid: UserGroup.stub.id)
    }
}
extension AuthManager {
    static let stub: AuthManager = .init(container: .stub)
    static var signedInAndHasGroupStub: AuthManager {
        let manager = AuthManager(container: .stub)
        manager.userInfo = .hasGroupStub
        manager.authState = .signedIn
        return manager
    }
}

typealias UserInfo = AuthManager.UserInfo
