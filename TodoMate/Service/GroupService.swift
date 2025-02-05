//
//  GroupService.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

final class GroupService: GroupServiceType {
    private let groupRepository: GroupRepositoryType

    init(groupRepository: GroupRepositoryType = FirestoreGroupRepository(reference: .shared)) {
        self.groupRepository = groupRepository
    }
}
extension GroupService {
    func fetch(groupId: String) async -> UserGroup? {
        print("[Fetching Group for \(groupId)] - ")
        return try? await groupRepository.fetchGroup(groupId: groupId).toModel()
    }
    
    func update(_ group: UserGroup) async {
        print("[Updating Group - \(group.id)] - ")
        do {
            try await groupRepository.updateGroup(group: group.toDTO())
        } catch {
            print("Error updating group: \(error)")
        }
    }
            
}

