//
//  FirestoreGroupRepository.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import Foundation

protocol GroupRepositoryType {
    func fetchGroup(groupId: String) async throws -> GroupDTO
    func updateGroup(group: GroupDTO) async throws
}

final class FirestoreGroupRepository: GroupRepositoryType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
}
#if !PREVIEW
extension FirestoreGroupRepository {
    func fetchGroup(groupId: String) async throws -> GroupDTO {
        let groupDocument = try await reference.groupCollection().document(groupId).getDocument()
        // TODO: - Group에 uids가 존재하지 않는 경우 처리 필요
        return try groupDocument.data(as: GroupDTO.self)
    }
    
    func updateGroup(group: GroupDTO) async throws {
        guard let groupId = group.id else { throw NSError(domain: "Group ID is nil", code: 0) }
        let groupDocRef = reference.groupCollection().document(groupId)
        try groupDocRef.setData(from: group)
    }
}
#else
extension FirestoreGroupRepository {
    func fetchGroup(groupId: String) async throws -> GroupDTO {
        return GroupDTO(id: "1", uids: [User.stub[0].uid, User.stub[1].uid])
    }
    
    func updateGroup(group: GroupDTO) async throws {
        print("Update group")
    }
}
#endif
