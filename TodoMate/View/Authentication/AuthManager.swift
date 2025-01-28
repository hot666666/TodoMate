//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//

import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftUI
import SwiftData

enum AuthError: Error {
    case invalidAppConfiguration
    case noActiveWindowScene
    case failedToGetToken
    case failedToGetUserID
}

protocol AuthManagerType {
    var authState: AuthManager.AuthState { get }
    var userInfo: AuthManager.UserInfo { get }
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
    
    init(userService: UserServiceType,
         userInfoService: UserInfoServiceType,
         modelContainer: ModelContainer) {
        self.userService = userService
        self.userInfoService = userInfoService
        self.modelContainer = modelContainer
        
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
            
            await createUserIfNeeded(uid: user.uid, name: user.displayName ?? "Unknown")
            await removeAllTodoEntity()
            userInfo = .init(id: user.uid, token: idToken)
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
}
extension AuthManager {
    private func createUserIfNeeded(uid: String, name: String) async {
        if let existingUser = await userService.fetch(uid: uid){
            print("User already exists with uid: \(existingUser.uid)")
            return
        }
        
        let newUser = User(nickname: name, uid: uid)
        userService.update(newUser)
        print("Created new user: \(newUser)")
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
    
    init(userService: UserServiceType,
         userInfoService: UserInfoServiceType,
         modelContainer: ModelContainer) {}
    
    @MainActor
    func signIn() async {
        authState = .loading
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        userInfo = .init(id: User.stub[0].uid, token: UUID().uuidString)
        print("User signed in")
        
        authState = .signedIn
    }
    
    @MainActor
    func signOut() async {
        userInfo = .empty
        
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
        
        static let empty = UserInfo(id: "", token: "")
        static let stub = UserInfo(id: User.stub[0].uid, token: UUID().uuidString)
    }
}
extension AuthManager {
    static let stub: AuthManager = .init(userService: StubUserService(),
                                         userInfoService: StubUserInfoService(),
                                         modelContainer: .forPreview())
}

typealias UserInfo = AuthManager.UserInfo
