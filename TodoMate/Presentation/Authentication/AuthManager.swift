//
//  AuthManager.swift
//  TodoMate
//
//  Created by hs on 3/1/25.
//

import Observation

@Observable
final class AuthManager {
    private let widgetDataManager: WidgetDataManagerType
    private let authService: AuthServiceType
    private let userInfoService: UserInfoServiceType
    /// Cached user information
    private var _authenticatedUser: AuthenticatedUser?
    
    private(set) var user: AuthenticatedUser? {
        get { _authenticatedUser }
        set {
            _authenticatedUser = newValue
            userInfoService.saveUserInfo(newValue)
        }
    }
    private(set) var state: State = .signedOut
    
    init(container: DIContainer = .stub) {
        self.authService = container.authService
        self.widgetDataManager = container.widgetDataManager
        self.userInfoService = container.userInfoService
        
        self._authenticatedUser = self.userInfoService.loadUserInfo()
    }
    
    @MainActor
    func signIn() async {
        state = .loading
        
        if let signedInUser = await authService.signIn() {
            let aUser = AuthenticatedUser(uid: signedInUser.uid, gid: signedInUser.gid)
            user = aUser
            state = .signedIn(aUser)
        } else {
            state = .signedOut
        }
    }
    
    @MainActor
    func signOut() async {
        defer {
            user = nil
            state = .signedOut
        }
        state = .loading
        
        await authService.signOut()
        await widgetDataManager.removeAll()
    }
    
    func updateUserGroup(_ gid: String) {
        if let user = user {
            self.user = AuthenticatedUser(uid: user.uid, gid: gid)
        }
    }
    
}
extension AuthManager {
    enum State {
        case signedOut
        case signedIn(AuthenticatedUser)
        case loading
    }
}
