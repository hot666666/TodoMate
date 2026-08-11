# Project-first legacy entity migration map

> 상태: HOT6-24 migration 계약. 이 문서는 target schema나 public Swift API가 아니라
> legacy input을 Project aggregate로 옮길 때 지켜야 할 데이터 의미와 fixture를 고정한다.
> 실제 GRDB schema는 HOT6-26, local Project backfill은 HOT6-27, per-Project General bootstrap과
> pure GroupMessage mapping seam은 HOT6-36이 소유한다. hosted source adapter와 실제 hosted
> Message import는 현재 Full Mock MVP 비목표다.
>
> Canonical source: [TodoMate Future Core Architecture v0.2](https://linear.app/hot6/document/todomate-future-core-architecture-v02-05b1682c21b0)

## 불변식

- Product Project가 유일한 최상위 workspace다. 개인 데이터도 멤버 한 명의 보통 Project에
  속하며 별도 `PersonalProject` aggregate를 만들지 않는다.
- Todo, Memo와 Message는 정확히 한 Project에 속한다. legacy Group은 별도 root로 남지 않고
  Shared Project와 그 Project의 General ChatChannel로 변환된다.
- 기존 content ID, 작성자와 tombstone을 가능한 한 보존한다. Project Owner라는 이유로 다른
  작성자의 author ID를 흡수하거나 해당 콘텐츠의 수정·삭제 권한을 얻지 않는다.
- migration은 source를 수정·삭제하지 않고 재실행 가능해야 한다. 일부 entity만 반영한 채
  완료 marker를 남기지 않는다.
- legacy Todo의 단일 `date`는 계획 시각 입력이다. `createdAt`, 상태 또는 `updatedAt`에서 실제
  시작·완료·재개 이력을 만들어 내지 않는다.
- 이 문서에서 쓰는 `SourceKey`, `AllocationJournal`, `MappingLedger`와
  `LegacyAuthorProvenance`는 필요한 의미를 설명하는 이름이다. HOT6-24가 동일한 이름의
  public type이나 table을 요구하지 않는다.

## 현재 source와 신뢰 경계

| source | 현재 포함 데이터 | Project migration에서의 권위 |
| --- | --- | --- |
| canonical App Group GRDB `todo` / `memo` | Todo, Memo, tombstone, `ownerId`, `localRevision`, 시간 필드 | 현재 실행 가능한 local source. Project 정보가 없으므로 한 local source scope 안의 행은 local Project 후보가 된다. |
| SwiftData 후보 store의 `ZSDTODO` / `ZSDMEMO` | GRDB 이전 Todo와 Memo | `LegacySwiftDataImporter`가 먼저 현재 GRDB projection으로 reconcile한다. Project migration이 SwiftData를 다시 독립적으로 읽어 이중 import하지 않는다. |
| 명시적으로 제공된 완전한 legacy hosted snapshot | `User`, `UserGroup`, `Todo`, `Memo`, `GroupMessage`와 source collection provenance | 후속 호환 import가 존재할 때만 Shared Project input으로 인정한다. 현재 앱은 Firebase runtime을 포함하지 않으므로 네트워크에서 이를 다시 읽지 않는다. |
| Sidebar `UserDefaults` cache | profile name, group name/ID, 표시 preference | entity source가 아니다. cache만으로 Project, Membership이나 authorship을 만들지 않는다. |
| Domain `Stub*`, Preview와 screenshot fixture | 가상 User/Group/Message | production migration input이 아니다. test scenario가 명시적으로 주입할 때만 fixture다. |
| `LegacyImportRepository` / `has_imported_legacy_data` | remote Firebase adapter는 제거됐지만 protocol/use case, Settings의 `LegacyImportSection`, Release app의 `StubLegacyImportRepository` wiring과 UserDefaults flag는 남아 있음 | Project migration source나 완료 근거가 아니다. DB transaction과 같은 storage의 versioned marker를 사용한다. |

현재 저장소에서 위 경계를 만드는 producer와 consumer는 다음과 같다.

- `TodoMateData/Sources/TodoMateData/GRDB/GRDBMigrations.swift`는 아직 ProjectID가 없는 Todo/Memo table과
  exact local author alias 정규화를 소유한다.
- `TodoMateData/Sources/TodoMateData/GRDB/LegacySwiftDataImporter.swift`는 SwiftData 후보를 읽고, 같은 ID의
  최신 source와 importer provenance를 현재 GRDB projection에 reconcile한다.
- `TodoMateData/Sources/TodoMateData/GRDB/GRDBAppGroupMigration.swift`의 generic backup 검증 로직은
  남아 있지만 app composition은 이전 Team-ID App Group을 migration source로 구성하지 않는다.
- Widget extension은 현재 제품과 Xcode target에서 제거되어 Project projection을 소비하지
  않는다. Data의 read-only reader는 후속 Widget 재도입 기반으로만 남아 있다.
- `TodoMate/AppIntent/**`는 현재 global local repository와 `User.local.id`를 사용한다.
- `User`, `UserGroup`, `GroupMessage`, `SessionStore`와 `MessageStore`는 legacy Group UI의
  의미를 보여 주지만 Release 구성은 현재 stub이므로 durable group source가 아니다.

따라서 HOT6-27의 실제 기본 입력은 **현재 canonical GRDB snapshot 하나**다. legacy hosted
snapshot 지원은 source provenance와 완전성 검증을 갖춘 별도 input이 있을 때만 활성화하며,
cache나 남은 type만 보고 과거 Group을 추측하지 않는다.

## 안정적인 source identity와 ID 정책

모든 결과는 다음 source identity로 추적할 수 있어야 한다.

```text
SourceKey = source namespace + entity kind + legacy ID
```

source namespace는 최소한 canonical local database identity와 명시적 hosted snapshot identity를
구분한다. filename, 현재 경로, 표시 이름이나 배열 index처럼 바뀔 수 있는 값은 identity가
아니다.

| target ID | 규칙 |
| --- | --- |
| ProjectID | legacy에는 같은 의미의 ID가 없으므로 새 ID를 한 번 발급하고 source workspace key → ProjectID를 ledger에 보존한다. local Project key와 `legacyGroupID` key는 서로 다른 namespace다. |
| TodoID / MemoID / MessageID | non-empty legacy ID가 해당 entity namespace에서 충돌하지 않으면 보존한다. source가 다른 두 logical entity의 raw ID가 충돌하면 조용히 덮어쓰지 않고 새 ID를 한 번 발급해 ledger와 legacy ID를 함께 보존한다. |
| ContentAuthorID | 아래 exact alias 집합만 `local-user`로 canonicalize한다. 그 밖의 non-empty raw ID는 trim, case-fold, prefix 처리 없이 서로 다른 author로 보존한다. |
| MembershipID | 새 ID를 한 번 발급하고 `(ProjectID, canonical ContentAuthorID)`에 연결한다. ledger는 이 membership으로 합쳐진 raw legacy user source key 목록도 보존한다. ContentAuthorID와 MembershipID는 같은 역할의 ID가 아니다. |
| ChatChannelID | Project마다 General channel ID를 한 번 발급해 ledger에 보존한다. `legacyGroupID`나 표시 이름 `General`을 ID로 사용하지 않는다. |

새 UUID와 seed는 canonical row를 만들기 전에 source signature로 식별한 durable preflight
`AllocationJournal`에 `pending` 상태로 기록한다. canonical generation이 rollback되더라도 같은
source signature의 retry는 pending allocation을 재사용한다. 다른 source signature는 기존
allocation을 조용히 재사용하거나 덮지 않고 source-drift diagnostic을 남긴다.

canonical source→target `MappingLedger`, target row, coverage 검증과 completion/cutover marker는
같은 result transaction에서 기록하고, 성공할 때 해당 journal generation도 `committed`로 바꾼다.
같은 `SourceKey`가 이미 다른 target에 연결됐거나 target ID가 다른 source에 연결된 경우
migration을 완료하지 않는다. 따라서 실패 뒤 pending journal이 남는 것은 완료나 partial
canonical row를 뜻하지 않지만 새 UUID/clock을 발급하지 않게 하는 재시도 입력이다.

## 작성자와 identity claim

현재 `LocalAuthorID`가 인정하는 exact placeholder alias는 다음 세 값뿐이다.

| before owner/author | after ContentAuthorID | mutation 의미 |
| --- | --- | --- |
| `""` | `local-user` | 같은 installation의 legacy local actor |
| `testUser` | `local-user` | 같은 installation의 legacy stub placeholder |
| `local-user` | `local-user` | idempotent |
| `firebase-user` | `firebase-user` | 별도 legacy author, 자동 claim 없음 |
| `stubUser` | `stubUser` | 별도 legacy author, 자동 claim 없음 |
| `TESTUSER` | `TESTUSER` | 별도 legacy author, 자동 claim 없음 |
| ` testUser ` | ` testUser ` | 별도 legacy author, trim하지 않음 |

`local-user`는 migration actor identity이며 Nostr public key나 Keychain identity private key가
아니다. HOT6-34가 identity를 만들더라도 DB open이나 sign-in을 계기로 author ID를 일괄
rewrite하지 않는다. identity 연결이 필요하면 다음 정보를 가진 명시적 provenance를 남긴다.

- source ContentAuthorID
- target IdentityID/public key
- HOT6-27 source ledger/completion proof: source workspace key, source signature와 marker version
- claim association method, 시각과 command/version
- association proof reference와 association schema/version

claim은 migration이 수행하는 단계가 아니다. HOT6-34 runtime command가 HOT6-27의 stable local
source workspace, completion proof/signature/version과 `local-user` provenance, 현재 Keychain
public identity를 함께 검증한 뒤 별도 versioned association을 추가한다. content row의
ContentAuthorID를 바꾸지 않고 authorization이 이 association을 해석한다. identity 생성, 복구나
DB open만으로 claim하지 않으며 proof mismatch와 이미 다른 identity가 claim한 경우 fail closed한다.

MVP에서 위 provenance가 없는 non-local legacy author는 **unclaimed historical author**다.
콘텐츠와 author 표시는 보존하지만 현재 Owner나 Member에게 mutation 권한을 주지 않는다.
향후 claim UX/증명 방식을 결정하기 전까지 해당 콘텐츠는 read-only다. 개인 local Project 안에
foreign author row가 있어도 active Membership을 새로 만들지 않으며, 이 때문에 1인 Project
불변식이 깨지지 않는다.

hosted Membership은 raw `memberIds` 순서를 그대로 role에 적용하지 않는다. 먼저 exact alias를
canonical ContentAuthorID로 바꾸고, canonical ID 기준으로 첫 등장 순서를 유지해 dedupe한 다음
첫 유효 canonical member를 Owner로 정한다. `testUser`/`local-user`처럼 명시적으로 같은
`local-user` alias로 선언된 raw source는 provenance 목록을 보존하며 하나의 Membership으로
합친다. alias 집합 밖의 서로 다른 raw source가 ledger corruption 등으로 같은 canonical ID에
연결되면 자동 merge하지 않고 해당 group generation을 fail closed한다.

## Local Project seed

legacy local source에는 Project 이름과 Project/Membership 생성 시각이 없다. migration은 다음
versioned seed를 target row보다 먼저 source signature에 묶인 AllocationJournal에 한 번 기록하고
retry 때 같은 값을 재사용한다.

```text
LocalProjectSeed(
  sourceWorkspaceKey: canonical local database identity,
  defaultName: "Private",
  generationInstant: injected clock instant
)
```

`"Private"`는 현재 Sidebar의 개인 영역 label을 보존하는 migration 기본 이름이며 cache/profile
문자열에서 추론하지 않는다. 사용자는 이후 보통 Project 이름처럼 변경할 수 있다. Project와
초기 Owner Membership의 `createdAt`/초기 `updatedAt`은 같은 persisted `generationInstant`를
쓴다. 재시도 때 wall clock을 다시 읽지 않으며 non-finite instant나 이미 다른 seed가 있는 경우
row를 만들기 전에 실패한다. 비어 있는 새 설치의 Project seed는 migration이 아니라 application
bootstrap이 별도로 소유한다.

## phase별 결정적인 생성 순서

물리 migration은 서로 다른 release에서 실행될 수 있으므로 하나의 전역 1–N transaction이나
marker를 미래 schema까지 기다리게 하지 않는다. 각 phase의 순서는 다음과 같다.

### Phase B · local Project cutover

1. migration lock을 잡고 fresh WAL-consistent backup/source signature를 고정한다.
2. local Todo/Memo/tombstone의 required field, non-finite date와 source collision을 검증한다.
3. source signature의 pending AllocationJournal을 재사용하거나 `LocalProjectSeed`, ProjectID와
   필요한 generated ID를 한 번 배정한다.
4. exact author alias를 canonicalize하고 source author provenance를 만든다.
5. local row가 하나라도 있으면 `"Private"` Project와 `local-user` Owner Membership을 만들고
   Todo/Memo/tombstone을 entity kind + legacy ID 순서로 parallel schema에 넣는다. 비어 있는 새
   설치의 default Project는 application bootstrap이 소유한다.
6. row coverage, foreign key, author, tombstone과 projection signature를 검증한다.
7. canonical rows/MappingLedger/cutover marker와 journal `committed` 전환을 같은 result
   transaction에서 commit한다. 실패하면 canonical row/marker 없이 pending allocation만 남긴다.

### Phase C · per-Project General bootstrap

1. Phase B 완료 뒤 현재 Project set signature를 고정한다.
2. 각 ProjectID 오름차순으로 existing General mapping을 확인하고 누락된 Project만 pending
   ChatChannelID allocation을 source/project-set signature의 AllocationJournal에 만든다.
3. deterministic General factory로 Project마다 정확히 하나를 만들고 cardinality를 검증한다.
4. Channel rows/MappingLedger/phase marker와 allocation `committed` 전환을 같은 transaction에서
   commit한다. 새 Project를 만드는 후속 phase는 같은 factory를 자신의 transaction에서 호출한다.

### Phase D · explicit hosted compatibility import (MVP 비목표)

1. 별도 승인된 adapter가 complete hosted snapshot/signature를 제공할 때만 시작한다.
2. UserGroup을 legacyGroupID 오름차순으로 처리해 Shared + Offline Project/Membership을 만든다.
3. 같은 transaction에서 Phase C General factory를 호출한다.
4. Project assignment가 확정된 Todo/Memo/Message를 넣고 full coverage/author/foreign key를
   검증한 뒤 phase D marker를 기록한다.

각 정렬은 결과 재현을 위한 처리 순서일 뿐 ID를 배열 index에서 만들기 위한 규칙이 아니다.

| phase | owner | atomic 완료 범위 |
| --- | --- | --- |
| A · current persistence baseline | 완료된 HOT6-5/6 | App Group 전환과 SwiftData → current GRDB reconcile |
| B · local Project backfill | HOT6-27 | Local Project/Membership과 Todo/Memo/tombstone Project/author provenance, validation과 canonical cutover |
| C · General bootstrap | HOT6-36, HOT6-27 뒤 | 존재하는 각 Project의 stable General ChatChannel, project-set signature와 pure legacy GroupMessage mapping seam. 실제 hosted Message import는 하지 않음 |
| D · explicit hosted compatibility import | 현재 Full Mock MVP 비목표 | complete snapshot adapter가 별도 승인될 때 Shared Project/Membership/content와 HOT6-36 계약을 소비한 General 생성 |

각 phase는 자신의 source signature, ledger subset, 검증과 marker를 갖고 재실행 안전해야 한다.
뒤 phase가 아직 배포되지 않았다는 이유로 앞 phase를 incomplete로 표시하지 않으며, 뒤 phase는
앞 phase의 stable ProjectID/author provenance를 소비한다. 특히 phase D가 추가된다면 phase C의
ChatChannel schema와 deterministic General factory를 선행 조건으로 삼고, 새 Shared Project와
General을 phase D transaction 안에서 함께 생성한다.

### Physical schema와 cutover boundary

HOT6-26은 production legacy Todo/Memo table에 non-null Project foreign key를 즉시 덧붙이지 않는다.
DDL 전 WAL-consistent recovery backup과 schema/source signature를 만든 뒤 Project-first table/index를
**additive parallel schema**로 생성한다. legacy table과 현재 writer/read path는 그대로 권위이고,
HOT6-26은 existing content migration/cutover completion marker를 남기지 않는다. empty schema와
isolated fixture에서만 Project foreign key를 검증한다.

HOT6-27은 app writer를 배제하는 cross-process migration lock 아래 최신 WAL-consistent pre-cutover
backup과 source signature를 새로 만든다. Widget은 write하지 않으며 cutover marker 전에는 legacy
read-only projection, marker 뒤에는 canonical read-only projection만 연다. 그 generation에서 pending
AllocationJournal의 stable seed/ID를 확정하고 parallel schema에 Local
Project/Membership/Todo/Memo/tombstone을 채운 뒤 row
coverage, foreign key, author, projection과 source drift를 검증한다. 검증과 canonical reader/writer
cutover marker는 같은 DB transaction에서 commit한다. 실패하면 marker 없이 target generation을
폐기하고 legacy path를 계속 사용한다. 성공 뒤에도 legacy table과 두 recovery backup을 삭제하거나
덮어쓰지 않는다.

따라서 HOT6-26 DDL 이전 backup은 schema bootstrap 복구점이고 HOT6-27의 fresh backup은 실제
content cutover 복구점이다. HOT6-27은 HOT6-26 당시 signature와 같다고 가정하지 않으며 최신
legacy source를 다시 서명한다.

## entity before → after map

| legacy entity / field | target Project-first 의미 | 보존·변환 규칙 |
| --- | --- | --- |
| local GRDB Todo | Local Project의 Todo | source가 hosted Group provenance를 갖지 않으면 local Project에 둔다. ID/content/detail/status/createdAt/updatedAt/tombstone과 `localRevision`을 보존한다. 저장된 `date` instant를 legacy planned-day 입력 하나로 보존하며 planned start/due 두 값이나 execution event를 합성하지 않는다. `localRevision`은 sync event revision이 아니다. |
| hosted snapshot Todo | provenance가 가리키는 Shared Project의 Todo | owner의 문자열만 보고 Group을 추측하지 않는다. snapshot이 명시한 group scope가 있을 때만 Shared Project에 둔다. local copy와 같은 logical SourceKey면 한 Todo로 reconcile하며 두 Project에 복제하지 않는다. |
| local GRDB Memo | Local Project의 Memo | ID/content/createdAt/updatedAt/tombstone, `localRevision`과 author를 보존한다. 제목은 새 canonical field를 만들지 않고 표시 시 첫 줄에서 파생한다. |
| hosted snapshot Memo | provenance가 가리키는 Shared Project의 Memo | Todo와 같은 explicit group-scope 규칙을 쓴다. 같은 logical SourceKey의 local/hosted copy를 중복 생성하지 않는다. |
| User.id | ContentAuthorID와 Membership source reference | exact alias 외 ID를 보존한다. displayName은 identity/profile snapshot일 뿐 mutation identity가 아니다. |
| User.displayName / createdAt / updatedAt | legacy profile snapshot/provenance | 사용자 표시와 audit에 보존할 수 있지만 immutable identity나 authorization input으로 쓰지 않는다. |
| User.groupId | UserGroup consistency evidence | Membership의 단독 권위가 아니다. `UserGroup.memberIds`와 불일치하면 diagnostic을 남기고 해당 hosted group generation을 완료하지 않는다. |
| UserGroup | Shared + Offline Project | 새 ProjectID를 발급하고 legacy ID/name/createdAt/updatedAt provenance를 보존한다. RelayBinding이나 Project key를 fabricated하지 않는다. 현재 importer가 active member가 아니면 결과 snapshot은 Detached read-only다. |
| UserGroup.memberIds | Membership 목록과 role | exact author alias canonicalization 뒤 canonical ContentAuthorID 기준으로 첫 등장 dedupe한다. legacy create/join 구현이 creator를 먼저 넣고 join을 append하므로 첫 번째 유효 canonical member를 Owner, 나머지를 Member로 매핑한다. raw alias provenance는 ledger에 보존하며 빈 목록/비-alias target collision은 group import를 fail closed한다. |
| GroupMessage.groupId | Project + General ChatChannel | matching UserGroup Project의 General channel로 바꾼다. matching group이 없으면 canonical Message를 만들지 않고 raw snapshot/diagnostic을 보존한다. |
| GroupMessage.owner | Message ContentAuthorID | exact author mapping을 적용한다. 현재 Member가 아니어도 과거 작성자는 보존하며 active Membership을 fabricated하지 않는다. |
| GroupMessage | Message | ID/content/createdAt/updatedAt를 보존한다. legacy model에 tombstone이 없으므로 삭제 이력을 합성하지 않는다. |
| Sidebar group/profile cache | UI preference 또는 폐기 | entity/membership source로 사용하지 않는다. 새 Project preference가 준비되면 legacy cache는 읽지 않되 데이터 backup과 무관한 preference cleanup 이슈가 삭제를 소유한다. |

Local, Hosted, Shared, Offline, Detached는 별도 aggregate type이 아니다. 위 표의 Local Project도
추후 같은 ProjectID를 유지한 채 host/share될 수 있고, imported Shared Project도 연결 상태와
membership에 따라 Offline 또는 Detached projection으로 보인다.

## hosted snapshot 완전성 규칙

현재 client는 hosted source를 읽지 않는다. 향후 호환 snapshot을 받는다면 다음 정보가 모두
있어야 해당 Group을 promote한다.

- snapshot namespace/version과 stable source identity
- `UserGroup` 한 건과 순서가 보존된 non-empty `memberIds`
- group에 속한다고 선언된 User/Todo/Memo/GroupMessage 각각의 source collection provenance
- source capture 시각/signature와 전체 또는 명시적 range라는 completeness 표시

`User.groupId`, cached group ID나 Message 한 건만으로 Shared Project를 만들지 않는다. incomplete
snapshot은 raw backup과 diagnostic을 보존하되 canonical row와 completion marker를 만들지 않는다.
이는 Firebase/Live Relay migration을 MVP에 다시 포함시키는 계약이 아니다.

## before / after fixture catalog

### F1-B · current local rows and Phase B cutover

```text
Before
  migration generation instant: 2026-08-10T00:00:00Z
  todo(id: T1, owner: "", deleted: false)
  todo(id: T2, owner: "firebase-user", deleted: false)
  todo(id: T3, owner: "stubUser", deleted: true)
  memo(id: M1, owner: "testUser", deleted: false)

After Phase B
  project(id: P-local-ledger, name: "Private", lifecycle: Local,
          createdAt: 2026-08-10T00:00:00Z)
  membership(project: P-local-ledger, author: local-user, role: Owner,
             createdAt: 2026-08-10T00:00:00Z)
  todo(id: T1, project: P-local-ledger, author: local-user, deleted: false)
  todo(id: T2, project: P-local-ledger, author: firebase-user, deleted: false,
       authorClaim: unclaimed)
  todo(id: T3, project: P-local-ledger, author: stubUser, deleted: true,
       authorClaim: unclaimed)
  memo(id: M1, project: P-local-ledger, author: local-user, deleted: false)
```

Expected: Project 하나, active Membership 하나와 content ID/tombstone을 보존하고 아직 General을
요구하지 않는다. active foreign-authored T2는 current actor `local-user`에게 view가 허용되지만
update/delete는 거부된다. T3는 이 권한 assertion과 별도로 tombstone 보존을 검증한다.
`firebase-user`를 Owner로 바꾸거나 새 active Member로 만들지 않는다. current actor `local-user`의
T2 거부는 persisted `readOnly` Boolean이나 tombstone 상태가 아니라 current actor와
ContentAuthorID/claim provenance에서 계산한 authorization 결과다.

### F1-C · Phase C General bootstrap

```text
Before Phase C
  project(id: P-local-ledger, Phase B marker: committed)
  no General channel mapping

After Phase C
  channel(id: C-local-general-ledger, project: P-local-ledger, name: General)
  exactly one General mapping for P-local-ledger
```

Expected: Phase B row/author/cutover 결과를 바꾸지 않고 General만 추가한다. 같은 Project set으로
재실행하면 ChannelID와 row count가 바뀌지 않는다.

### F2 · complete legacy Group snapshot

```text
Before
  group(id: G1, memberIds: [U2, U1], name: "Study")
  user(id: U2, groupId: G1)
  user(id: U1, groupId: G1)
  todo(id: T9, owner: U1, groupProvenance: G1)
  memo(id: M9, owner: U2, groupProvenance: G1)
  message(id: MSG1, groupId: G1, owner: U1)

After
  project(id: P-G1-ledger, legacyGroupID: G1, lifecycle: Shared + Offline)
  membership(project: P-G1-ledger, author: U2, role: Owner)
  membership(project: P-G1-ledger, author: U1, role: Member)
  channel(id: C-G1-general-ledger, project: P-G1-ledger, name: General)
  todo(id: T9, project: P-G1-ledger, author: U1)
  memo(id: M9, project: P-G1-ledger, author: U2)
  message(id: MSG1, project: P-G1-ledger, channel: C-G1-general-ledger, author: U1)
```

Expected: legacy Group와 Channel을 별도 root로 유지하지 않는다. 새 RelayBinding, key epoch,
KeyEnvelope 또는 signature를 만들어 과거 데이터가 원래 암호화·서명됐던 것처럼 취급하지
않는다.

### F3 · local/hosted overlap과 재실행

```text
Before generation 1
  local todo T1 updatedAt: 10, logical source key: S/Todo/T1
  hosted copy T1 updatedAt: 10, explicitly correlated logical source key: S/Todo/T1,
    group provenance: G1

After generation 1
  exactly one Todo T1 in P-G1-ledger

Before generation 2
  identical snapshot and existing mapping ledger

After generation 2
  same ProjectID, ChannelID and TodoID; row counts unchanged
```

Expected: explicit correlation evidence로 logical SourceKey가 같은 copy만 reconcile한다. raw
ID만 같은 다른 namespace의 entity는 자동 merge하지 않는다. imported row를 사용자가 이미 수정했다면 현재
`LegacyImportReconciler`처럼 importer-owned revision/provenance가 일치할 때만 더 최신 source로
교체하며, 그렇지 않으면 local edit를 덮지 않고 conflict diagnostic을 남긴다.

### F4 · incomplete or conflicting input

```text
Before
  group G-empty with memberIds: []
  message MSG-orphan with groupId: G-missing
  a corrupt existing ledger mapping two distinct SourceKeys to the same target TodoID

After
  no completion marker for the failed generation
  no partial Project/Membership/Message rows from that generation
  source backup and typed diagnostics retained
```

Expected: Owner를 임의 선택하거나 orphan Message를 local Project에 넣거나 Todo를 덮어쓰지 않는다.

### F5 · cache-only Group hint

```text
Before
  UserDefaults cachedGroupID: G-cache
  UserDefaults cachedGroupName: "Old Group"
  no complete hosted snapshot

After
  no Shared Project and no Membership created from G-cache
```

Expected: 표시 cache를 entity source로 승격하지 않는다.

### F6 · canonical author alias collision (future Phase D contract)

```text
Before
  group(id: G-alias, memberIds: ["testUser", "local-user", "U2"])
  user(id: "testUser", groupId: G-alias)
  user(id: "local-user", groupId: G-alias)
  user(id: U2, groupId: G-alias)

After
  membership(project: P-G-alias-ledger, author: local-user, role: Owner,
             rawSources: ["testUser", "local-user"])
  membership(project: P-G-alias-ledger, author: U2, role: Member,
             rawSources: [U2])
```

Expected: author canonicalization 뒤 canonical ID 기준으로 role을 정하므로 `local-user`
Membership은 정확히 하나다. 두 raw alias provenance는 ledger에 남는다. alias 집합 밖의 서로
다른 source가 같은 canonical target에 매핑된 fixture는 completion marker 없이 fail closed한다.
이 hosted Membership fixture는 HOT6-27 local migration test가 아니며 Phase D adapter가 별도
승인될 때 그 compatibility suite가 소비한다.

## backup, rollback과 restart 경계

- 등록형 App Group 전환은 기존 `GRDBAppGroupMigration`의 marker/signature/atomic promotion을
  먼저 완료한다. Project migration이 이 container migration을 재구현하지 않는다.
- HOT6-26은 additive parallel DDL 전에 schema-bootstrap recovery backup/signature를 만들고,
  HOT6-27은 migration lock 아래 content cutover 직전 최신 WAL-consistent backup/signature를
  별도로 만든다. 기존 legacy GRDB와 SwiftData store도 삭제하지 않는다.
- source read, mapping과 검증은 generation 단위다. source drift, rejected row, unrecognized
  source, collision, invariant 실패가 하나라도 있으면 completion marker를 지우거나 남기지
  않고 transaction/staging 결과를 폐기한다.
- crash 뒤에는 source signature에 묶인 pending AllocationJournal과 DB 안 versioned marker,
  MappingLedger/per-record provenance로 재개한다. pending은 완료 신호가 아니며 UserDefaults flag나
  UI 진입 여부도 완료 신호로 사용하지 않는다.
- 성공 뒤 사용자가 새 Project 데이터를 편집했다면 자동 rollback으로 database 전체를 과거
  backup에 덮어쓰지 않는다. recovery restore는 post-migration edit 손실을 명시하는 별도
  사용자/지원 경로가 소유한다.
- backup 보존 기간과 사용자 노출 삭제 정책은 HOT6-27의 호환성 checkpoint다. HOT6-24는
  자동 삭제를 승인하지 않는다.

## Project-scoped consumer handoff

| consumer | migration 이후 필요한 입력 | 금지되는 fallback |
| --- | --- | --- |
| Widget read model | ProjectID, date range, 같은 TodoID의 read-only projection, lifecycle readable 여부 | 모든 Project의 Todo를 global query로 섞거나 Widget이 migration/write 수행 |
| AppIntent Todo/Memo | explicit ProjectID 또는 app이 관리하는 deterministic selected/default ProjectID, current ContentAuthorID | `User.local.id`를 모든 author로 간주하거나 global repository에 쓰기 |
| Kanban / Calendar / Timeline | `(ProjectID, TodoID)`와 각 mode projection | mode별 Todo 복제, legacy `date`에서 execution event 합성 |
| Smart View | Project별 projection과 typed scope input | HOT6-48 review 전 current Project/all Project scope를 migration이 결정 |
| Chat | ProjectID, General ChatChannelID, MessageID, ContentAuthorID | GroupID를 route identity로 계속 사용하거나 Message를 Todo 보조 panel에 배치 |

Widget과 AppIntent의 실제 Project 선택 UX는 consumer 이슈가 소유한다. migration은 모든 row가
ProjectID로 질의 가능하고 선택되지 않은 Project를 실수로 mutate하지 않을 입력만 제공한다.

## 후속 issue ownership

| issue | 이 문서에서 받는 handoff |
| --- | --- |
| HOT6-26 | typed Project/author ID, additive parallel Project/Membership/Todo/Memo schema, pre-DDL schema backup/signature, pending allocation journal/ledger/provenance storage와 Data fixture seam. existing content cutover/marker는 소유하지 않음 |
| HOT6-27 | phase B의 fresh pre-cutover backup/signature, migration lock, pending allocation journal, 실제 local Project generation, validation + atomic reader/writer cutover, restart, seed/collision/incomplete failure와 F1-B local alias/active foreign-author test. General/hosted Group import는 소유하지 않음 |
| HOT6-28/29/31 | local Project/Todo/Memo consumer와 Project-scoped AppIntent/Widget 조립 |
| HOT6-34 | `local-user` ledger proof + Keychain public identity를 검증하는 명시적 claim command/provenance; foreign ID/content row 자동 rewrite 금지 |
| HOT6-36 | HOT6-27 뒤 phase C의 per-Project idempotent General schema/bootstrap과 F1-C, pure GroupMessage mapping seam. actual hosted import는 phase D 비목표 |
| future Phase D compatibility adapter | F2–F6 hosted snapshot mapping contract. Full Mock MVP 비목표이며 별도 승인 전 구현/test 완료 gate가 아님 |
| HOT6-47 | claimed author-only mutation, historical author read-only와 membership role enforcement |
| HOT6-8/9 | ProjectID route와 Project-scoped Screen/TCA consumer; entity migration UX는 구현 issue에서 별도 처리 |

## 검증 범위

이 변경은 production migration을 실행하지 않는다. 현재 baseline이 깨지지 않았음과 문서
coverage만 다음으로 확인한다.

```bash
just test-data
git diff --check
```

추가로 F1-B/F1-C와 future Phase D용 F2–F6이 Todo, Memo, User, UserGroup, GroupMessage,
ID/author/membership, duplicate, restart, backup/rollback과 Widget/AppIntent/Smart View 입력을
모두 포함하는지 검토하고 relative Markdown link가 실제 repository path를 가리키는지 확인한다.
hosted contract fixture의 문서 PASS를 구현/test evidence로, 문서 전체 PASS를 실제 Project schema
migration proof로 부르지 않는다.
