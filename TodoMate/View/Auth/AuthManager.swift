//
//  AuthViewModel.swift
//  TodoMate
//
//  Created by hs on 1/19/25.
//


import FirebaseCore
import FirebaseAuth
import GoogleSignIn

protocol AuthManagerType {
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var userId: String? { get }
    func signIn() async
    func signOut()
}

#if !PREVIEW
@Observable
class AuthManager: AuthManagerType {
    private let userService: UserServiceType
    private let userDefaults = UserDefaults.standard
    
    private var _userId: String?
    private var _userToken: String?
    
    var isLoggedIn: Bool { userToken != nil && userId != nil }
    var isLoading = false
    
    private(set) var userId: String? {
        get { _userId }
        set {
            _userId = newValue
            userDefaults.set(newValue, forKey: "userId")
        }
    }
    
    private var userToken: String? {
        get { _userToken }
        set {
            _userToken = newValue
            userDefaults.set(newValue, forKey: "userToken")
        }
    }
    
    init(userService: UserServiceType) {
        self.userService = userService
        self._userId = userDefaults.string(forKey: "userId")
        self._userToken = userDefaults.string(forKey: "userToken")
    }
    
    @MainActor
    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let clientId = FirebaseApp.app()?.options.clientID,
                  let windowScene = NSApplication.shared.windows.first else {
                print("Error: Invalid app configuration")
                return
            }
            
            let configuration = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: windowScene)
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("Error: Failed to get authentication token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            await createUserIfNeeded(uid: user.uid, name: user.displayName ?? "Unknown")
            
            userId = user.uid
            userToken = idToken
            print("Sign in successful for user: \(user.uid)")
            
        } catch {
            print("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        userToken = nil
        userId = nil
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
}
#else
@Observable
class AuthManager: AuthManagerType {
    var isLoggedIn: Bool = false
    var isLoading: Bool = false
    var userId: String?
    
    init(userService: UserServiceType) {}
    
    @MainActor
    func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("User signed in")
        isLoggedIn = true
        userId = "user_id"
    }
    
    func signOut() {
        print("User signed out")
        isLoggedIn = false
        userId = nil
    }
}
#endif



extension AuthManager {
    static let stub: AuthManager = .init(userService: StubUserService())
}
