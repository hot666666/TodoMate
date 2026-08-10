import Testing

@testable import TodoMateDomain

@Suite("Project mutation authorization contract")
struct ProjectMutationAuthorizationTests {
  @Test("Content fixture matrix covers every entry point, resource, mutation, and scenario")
  func contentFixtureMatrixIsComplete() {
    let expectedCount =
      AuthorizationEntryPoint.allCases.count
      * AuthorizationResource.allCases.count
      * AuthorizationMutation.allCases.count
      * AuthorizationScenario.allCases.count

    #expect(ContentAuthorizationFixture.all.count == expectedCount)

    for entryPoint in AuthorizationEntryPoint.allCases {
      for resource in AuthorizationResource.allCases {
        for mutation in AuthorizationMutation.allCases {
          for scenario in AuthorizationScenario.allCases {
            let matches = ContentAuthorizationFixture.all.filter {
              $0.entryPoint == entryPoint
                && $0.resource == resource
                && $0.mutation == mutation
                && $0.scenario == scenario
            }
            #expect(matches.count == 1)
            #expect(matches.first?.evidence == scenario.evidence)
            #expect(matches.first?.expectedDecision == scenario.expectedDecision)
            #expect(
              matches.first?.expectedDecision
                == expectedDecision(for: scenario.evidence)
            )
          }
        }
      }
    }
  }

  @Test("Local command and inbound reconcile use the same content decision matrix")
  func localAndInboundDecisionsMatch() {
    for resource in AuthorizationResource.allCases {
      for mutation in AuthorizationMutation.allCases {
        for scenario in AuthorizationScenario.allCases {
          let local = fixture(
            entryPoint: .localCommand,
            resource: resource,
            mutation: mutation,
            scenario: scenario
          )
          let inbound = fixture(
            entryPoint: .inboundReconcile,
            resource: resource,
            mutation: mutation,
            scenario: scenario
          )

          #expect(local?.expectedDecision == inbound?.expectedDecision)
        }
      }
    }
  }

  @Test("Owner role never bypasses another content author")
  func ownerCannotMutateAnotherAuthorsContent() {
    let ownerBypassAttempts = ContentAuthorizationFixture.all.filter {
      $0.scenario == .contentAuthorMismatchForOwner
    }

    #expect(!ownerBypassAttempts.isEmpty)
    #expect(
      ownerBypassAttempts.allSatisfy {
        $0.expectedDecision == .denied(.contentAuthorMismatch)
      }
    )
  }

  @Test("Detached and non-member content mutations are fail-closed")
  func inactiveMembershipCannotMutateContent() {
    let inactiveAttempts = ContentAuthorizationFixture.all.filter {
      $0.scenario == .detachedSnapshot || $0.scenario == .notMember
    }

    #expect(!inactiveAttempts.isEmpty)
    #expect(
      inactiveAttempts.allSatisfy {
        $0.expectedDecision == .denied(.inactiveMembership)
      }
    )
  }

  @Test("Conflict catalog contains each required scenario exactly once")
  func conflictCatalogIsComplete() {
    #expect(ConflictFixture.all.count == ConflictScenario.allCases.count)
    #expect(Set(ConflictFixture.all.map(\.scenario)) == Set(ConflictScenario.allCases))
    #expect(ConflictFixture.all.allSatisfy { $0.deliveryPermutations.count >= 2 })
  }

  @Test("Todo same-field tie remains an explicit product checkpoint without a winner")
  func todoSameFieldTieFailsClosed() {
    let fixture = ConflictFixture.all.first {
      $0.scenario == .todoEqualSameFieldRevision
    }

    #expect(
      fixture?.expectedInvariant
        == .requiresProductDecision(.todoSameFieldTieBreaker)
    )
  }

  @Test("Removal race oracle rejects causally-later writes in every delivery order")
  func removalRaceRejectsWrite() {
    let fixture = ConflictFixture.all.first {
      $0.scenario == .causallyAfterRemovalWrite
    }

    #expect(fixture?.deliveryPermutations.count == 2)
    #expect(fixture?.expectedInvariant == .rejectsWriteAndQuarantinesOutbox)
  }

  private func fixture(
    entryPoint: AuthorizationEntryPoint,
    resource: AuthorizationResource,
    mutation: AuthorizationMutation,
    scenario: AuthorizationScenario
  ) -> ContentAuthorizationFixture? {
    ContentAuthorizationFixture.all.first {
      $0.entryPoint == entryPoint
        && $0.resource == resource
        && $0.mutation == mutation
        && $0.scenario == scenario
    }
  }

  private func expectedDecision(
    for evidence: AuthorizationFixtureEvidence
  ) -> AuthorizationFixtureDecision {
    guard evidence.verifiedActor == evidence.operationAuthor else {
      return .denied(.operationAuthorMismatch)
    }
    guard evidence.membership == .activeOwner || evidence.membership == .activeMember else {
      return .denied(.inactiveMembership)
    }
    guard evidence.verifiedActor == evidence.entityAuthor else {
      return .denied(.contentAuthorMismatch)
    }
    return .allowed
  }
}
