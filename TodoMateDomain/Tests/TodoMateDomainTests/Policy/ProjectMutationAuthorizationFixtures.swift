enum AuthorizationEntryPoint: CaseIterable, Hashable, Sendable {
  case localCommand
  case inboundReconcile
}

enum AuthorizationResource: CaseIterable, Hashable, Sendable {
  case todo
  case memo
  case message
}

enum AuthorizationMutation: CaseIterable, Hashable, Sendable {
  case create
  case update
  case delete
}

enum AuthorizationScenario: CaseIterable, Hashable, Sendable {
  case activeMemberOwnContent
  case activeOwnerOwnContent
  case operationAuthorMismatch
  case contentAuthorMismatchForMember
  case contentAuthorMismatchForOwner
  case detachedSnapshot
  case notMember

  var evidence: AuthorizationFixtureEvidence {
    switch self {
    case .activeMemberOwnContent:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .firstAuthor,
        membership: .activeMember
      )
    case .activeOwnerOwnContent:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .firstAuthor,
        membership: .activeOwner
      )
    case .operationAuthorMismatch:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .secondAuthor,
        entityAuthor: .firstAuthor,
        membership: .activeMember
      )
    case .contentAuthorMismatchForMember:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .secondAuthor,
        membership: .activeMember
      )
    case .contentAuthorMismatchForOwner:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .secondAuthor,
        membership: .activeOwner
      )
    case .detachedSnapshot:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .firstAuthor,
        membership: .detached
      )
    case .notMember:
      AuthorizationFixtureEvidence(
        verifiedActor: .firstAuthor,
        operationAuthor: .firstAuthor,
        entityAuthor: .firstAuthor,
        membership: .notMember
      )
    }
  }

  var expectedDecision: AuthorizationFixtureDecision {
    switch self {
    case .activeMemberOwnContent, .activeOwnerOwnContent:
      .allowed
    case .operationAuthorMismatch:
      .denied(.operationAuthorMismatch)
    case .contentAuthorMismatchForMember, .contentAuthorMismatchForOwner:
      .denied(.contentAuthorMismatch)
    case .detachedSnapshot, .notMember:
      .denied(.inactiveMembership)
    }
  }
}

enum AuthorizationFixturePrincipal: Equatable, Sendable {
  case firstAuthor
  case secondAuthor
}

enum AuthorizationMembershipEvidence: Equatable, Sendable {
  case activeOwner
  case activeMember
  case detached
  case notMember
}

struct AuthorizationFixtureEvidence: Equatable, Sendable {
  let verifiedActor: AuthorizationFixturePrincipal
  let operationAuthor: AuthorizationFixturePrincipal
  let entityAuthor: AuthorizationFixturePrincipal
  let membership: AuthorizationMembershipEvidence
}

enum AuthorizationFixtureDenial: Equatable, Sendable {
  case operationAuthorMismatch
  case inactiveMembership
  case contentAuthorMismatch
}

enum AuthorizationFixtureDecision: Equatable, Sendable {
  case allowed
  case denied(AuthorizationFixtureDenial)
}

struct ContentAuthorizationFixture: Sendable {
  let entryPoint: AuthorizationEntryPoint
  let resource: AuthorizationResource
  let mutation: AuthorizationMutation
  let scenario: AuthorizationScenario
  let evidence: AuthorizationFixtureEvidence
  let expectedDecision: AuthorizationFixtureDecision

  static let all: [Self] = AuthorizationEntryPoint.allCases.flatMap { entryPoint in
    AuthorizationResource.allCases.flatMap { resource in
      AuthorizationMutation.allCases.flatMap { mutation in
        AuthorizationScenario.allCases.map { scenario in
          Self(
            entryPoint: entryPoint,
            resource: resource,
            mutation: mutation,
            scenario: scenario,
            evidence: scenario.evidence,
            expectedDecision: scenario.expectedDecision
          )
        }
      }
    }
  }
}

enum ConflictScenario: CaseIterable, Hashable, Sendable {
  case todoDifferentFields
  case todoHigherFieldRevision
  case todoEqualSameFieldRevision
  case memoWholeDocument
  case messageCreates
  case ownershipTransfer
  case duplicateOperation
  case staleOperation
  case unauthorizedOperation
  case causallyAfterRemovalWrite
}

enum ConflictEvent: Sendable {
  case todoTitleEdit
  case todoScheduleEdit
  case todoLowerFieldRevision
  case todoHigherFieldRevision
  case todoSameFieldTieFromFirstAuthor
  case todoSameFieldTieFromSecondAuthor
  case memoFirstRevision
  case memoConcurrentHigherRevision
  case firstMessageCreate
  case secondMessageCreate
  case ownershipTransferRequest
  case ownershipTransferAcceptance
  case acceptedOperation
  case duplicateOfAcceptedOperation
  case currentOperation
  case staleOperation
  case unauthorizedOperation
  case memberRemoval
  case causallyAfterRemovalWrite
}

enum ProductDecisionCheckpoint: Equatable, Sendable {
  case todoSameFieldTieBreaker
}

enum ConflictExpectedInvariant: Equatable, Sendable {
  case mergesDifferentTodoFields
  case selectsHigherTodoFieldRevision
  case requiresProductDecision(ProductDecisionCheckpoint)
  case selectsHigherMemoRevisionAndPreservesConflictHistory
  case preservesAllMessageCreates
  case transfersOwnershipAfterRequestAndAcceptance
  case appliesOneLogicalEffect
  case ignoresStaleOperation
  case ignoresUnauthorizedOperation
  case rejectsWriteAndQuarantinesOutbox
}

struct ConflictFixture: Sendable {
  let scenario: ConflictScenario
  let deliveryPermutations: [[ConflictEvent]]
  let expectedInvariant: ConflictExpectedInvariant

  static let all: [Self] = [
    Self(
      scenario: .todoDifferentFields,
      deliveryPermutations: [
        [.todoTitleEdit, .todoScheduleEdit],
        [.todoScheduleEdit, .todoTitleEdit],
      ],
      expectedInvariant: .mergesDifferentTodoFields
    ),
    Self(
      scenario: .todoHigherFieldRevision,
      deliveryPermutations: [
        [.todoLowerFieldRevision, .todoHigherFieldRevision],
        [.todoHigherFieldRevision, .todoLowerFieldRevision],
      ],
      expectedInvariant: .selectsHigherTodoFieldRevision
    ),
    Self(
      scenario: .todoEqualSameFieldRevision,
      deliveryPermutations: [
        [.todoSameFieldTieFromFirstAuthor, .todoSameFieldTieFromSecondAuthor],
        [.todoSameFieldTieFromSecondAuthor, .todoSameFieldTieFromFirstAuthor],
      ],
      expectedInvariant: .requiresProductDecision(.todoSameFieldTieBreaker)
    ),
    Self(
      scenario: .memoWholeDocument,
      deliveryPermutations: [
        [.memoFirstRevision, .memoConcurrentHigherRevision],
        [.memoConcurrentHigherRevision, .memoFirstRevision],
      ],
      expectedInvariant: .selectsHigherMemoRevisionAndPreservesConflictHistory
    ),
    Self(
      scenario: .messageCreates,
      deliveryPermutations: [
        [.firstMessageCreate, .secondMessageCreate],
        [.secondMessageCreate, .firstMessageCreate],
      ],
      expectedInvariant: .preservesAllMessageCreates
    ),
    Self(
      scenario: .ownershipTransfer,
      deliveryPermutations: [
        [.ownershipTransferRequest, .ownershipTransferAcceptance],
        [.ownershipTransferAcceptance, .ownershipTransferRequest],
      ],
      expectedInvariant: .transfersOwnershipAfterRequestAndAcceptance
    ),
    Self(
      scenario: .duplicateOperation,
      deliveryPermutations: [
        [.acceptedOperation, .duplicateOfAcceptedOperation],
        [.duplicateOfAcceptedOperation, .acceptedOperation],
      ],
      expectedInvariant: .appliesOneLogicalEffect
    ),
    Self(
      scenario: .staleOperation,
      deliveryPermutations: [
        [.currentOperation, .staleOperation],
        [.staleOperation, .currentOperation],
      ],
      expectedInvariant: .ignoresStaleOperation
    ),
    Self(
      scenario: .unauthorizedOperation,
      deliveryPermutations: [
        [.currentOperation, .unauthorizedOperation],
        [.unauthorizedOperation, .currentOperation],
      ],
      expectedInvariant: .ignoresUnauthorizedOperation
    ),
    Self(
      scenario: .causallyAfterRemovalWrite,
      deliveryPermutations: [
        [.memberRemoval, .causallyAfterRemovalWrite],
        [.causallyAfterRemovalWrite, .memberRemoval],
      ],
      expectedInvariant: .rejectsWriteAndQuarantinesOutbox
    ),
  ]
}
