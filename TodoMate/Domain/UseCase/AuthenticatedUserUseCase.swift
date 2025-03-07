//
//  AuthenticatedUserUseCase.swift
//  TodoMate
//
//  Created by hs on 3/6/25.
//

protocol FetchAuthenticatedUserUseCaseType {
    func execute() -> AuthenticatedUser?
}

final class FetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType {
    private let userInfoService: UserInfoServiceType
    
    init(userInfoService: UserInfoServiceType) {
        self.userInfoService = userInfoService
    }
    
    func execute() -> AuthenticatedUser? {
        try? userInfoService.loadUserInfo()
    }
}

class StubFetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType {
    func execute() -> AuthenticatedUser? {
        .stub
    }
}

// MARK: - GroupService도 현재 사용되지 않음
//class UpdateAuthenticatedUserGroupUseCase {
//    private let userInfoService: UserInfoServiceType
//    
//    init(userInfoService: UserInfoServiceType) {
//        self.userInfoService = userInfoService
//    }
//    
//    func execute(aUser: AuthenticatedUser, with gid: String) throws -> AuthenticatedUser {
//        // 도메인 로직
//        var updatedUser = aUser
//        updatedUser.gid = gid
//        
//        try userInfoService.saveUserInfo(aUser)
//        return updatedUser
//    }
//    
//    /*
//     func updateUserGroup(_ gid: String) {
//         guard
//             let aUser = authenticatedUser,
//             let updatedAUser = try? updateAUserGroupUseCase.execute(aUser: aUser, with: gid)
//         else {
//             print("Failed to update a user group")
//             return
//         }
//         
//         authenticatedUser = updatedAUser
//     }
//     */
//}

