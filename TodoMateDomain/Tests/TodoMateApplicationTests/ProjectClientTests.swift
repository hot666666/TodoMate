import Foundation
import Testing
import TodoMateDomain
@testable import TodoMateApplication

@Suite("ProjectClient")
struct ProjectClientTests {
  @Test("Creating a local Project preserves typed identity and selects it")
  func createAndSelect() async throws {
    let persistence = InMemoryProjectPersistence()
    let expectedID = ProjectID(rawValue: "project-1")
    let expectedMembershipID = MembershipID(rawValue: "membership-1")
    let expectedDate = Date(timeIntervalSince1970: 1_786_363_200)
    let client = ProjectClient.live(
      persistence: persistence,
      generateID: { expectedID },
      generateMembershipID: { expectedMembershipID },
      now: { expectedDate }
    )

    let createdID = try await client.createLocal(.init(name: "  Daily  "))
    let snapshot = await persistence.snapshot()

    #expect(createdID == expectedID)
    #expect(snapshot.selectedProjectID == expectedID)
    #expect(snapshot.projects == [
      Project(
        id: expectedID,
        name: try ProjectName("Daily"),
        lifecycle: .local,
        createdAt: expectedDate,
        updatedAt: expectedDate
      ),
    ])
    #expect(await persistence.memberships() == [
      Membership(
        id: expectedMembershipID,
        projectID: expectedID,
        authorID: ContentAuthorID(rawValue: User.local.id),
        role: .owner,
        createdAt: expectedDate
      ),
    ])
  }
}

private actor InMemoryProjectPersistence: ProjectPersistence {
  private var current = ProjectWorkspaceSnapshot(projects: [], selectedProjectID: nil)
  private var storedMemberships: [Membership] = []

  nonisolated func snapshots() -> AsyncStream<ProjectWorkspaceSnapshot> {
    AsyncStream { continuation in
      Task {
        continuation.yield(await snapshot())
        continuation.finish()
      }
    }
  }

  func create(_ project: Project, ownerMembership: Membership, selecting: Bool) {
    current.projects.append(project)
    storedMemberships.append(ownerMembership)
    if selecting { current.selectedProjectID = project.id }
  }

  func select(_ projectID: ProjectID) throws {
    guard current.projects.contains(where: { $0.id == projectID }) else {
      throw PersistenceError.missingProject
    }
    current.selectedProjectID = projectID
  }

  func snapshot() -> ProjectWorkspaceSnapshot { current }
  func memberships() -> [Membership] { storedMemberships }

  enum PersistenceError: Error {
    case missingProject
  }
}
