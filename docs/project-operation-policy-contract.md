# ProjectOperation authorization·conflict semantic contract

이 문서는 HOT6-47의 reversible policy slice다. Project 중심 공유 상태에서 local command와
inbound operation이 따라야 할 authorization matrix, membership transition과 conflict fixture의
기대 결과를 고정한다.

이 문서는 transport DTO, GRDB schema 또는 Swift public API가 아니다. `ProjectID`,
`ContentAuthorID`, `ProjectOperation`, revision과 event ordering의 실제 타입은 각 producer issue가
만든다. 이 문서와 `TodoMateDomain/Tests/.../Policy` fixture는 그 구현이 소비할 semantic oracle이다.

## 이번 slice가 증명하는 것과 증명하지 않는 것

증명한다.

- Todo·Memo·Message의 create/update/delete에 같은 author-only 규칙을 적용한다.
- local command와 inbound reconcile의 기대 decision matrix가 같다.
- Owner도 다른 작성자의 content를 수정·삭제할 수 없다.
- Detached와 non-member는 원 Project에 write할 수 없다.
- membership, Channel metadata와 Detached copy capability가 content author 권한과 분리된다.
- conflict fixture가 delivery permutation과 기대 invariant를 typed test-only catalog로 제공한다.
- Todo same-field 동률에는 아직 승자를 만들지 않고 product decision checkpoint로 실패한다.

아직 증명하지 않는다.

- production Domain authorization 함수가 local Application client와 SyncEngine에서 실제 호출됨
- unauthorized operation이 GRDB projection/outbox를 바꾸지 않음
- 두 client의 offline/reconnect, duplicate/out-of-order와 removal race가 실제로 수렴함
- signature, encryption, key epoch, Relay ACK/cursor 또는 durable outbox schema
- Todo same-field 동률의 최종 comparator

위 integration 증거는 HOT6-26/33/35가 만든 타입과 runtime을 HOT6-7이 조립한 뒤
`just test-sync`와 Data integration test에서 만든다. 이 fixture의 성공을 SyncEngine 또는 GRDB
증거라고 부르지 않는다.

## 용어와 독립된 입력 축

| 입력 | 의미 | 대체하면 안 되는 것 |
| --- | --- | --- |
| verified actor | local에서는 현재 identity, inbound에서는 검증된 signature의 identity | 표시 이름, operation payload가 주장한 author |
| operation author | 복호화된 operation이 주장하는 작성 identity | verified actor와 비교하지 않은 문자열 |
| entity author | Todo·Memo·Message가 보존하는 immutable ContentAuthorID | Project Owner, 현재 display name |
| membership evidence | 해당 Project에서 actor가 active Owner/Member인지, Detached/non-member인지 | content author 일치 여부 |
| capability | settings, membership, Channel metadata, Detached copy처럼 mutation별 권한 | Owner라는 하나의 전역 write 권한 |
| ordering evidence | revision, accepted cursor 또는 causal predecessor처럼 future reconcile이 검증할 순서 근거 | wall clock이나 전달 순서 |

이 축은 서로 독립적으로 판정한다. `active Owner`는 membership/settings capability를 주지만
`entity author`를 바꾸지 않는다. `entity author == actor`여도 membership이 inactive면 원 Project
write는 거부한다.

## Content mutation authorization

### 공통 판정 순서

Todo·Memo·Message의 create/update/delete는 resource나 entry point에 관계없이 다음 순서를
따른다.

1. trusted context가 제공한 verified actor와 operation author가 정확히 같아야 한다.
2. actor가 해당 Project의 active Owner 또는 active Member여야 한다.
3. verified actor와 entity author가 정확히 같아야 한다.
4. 세 조건이 모두 참일 때만 mutation을 다음 reconcile 단계로 보낸다.

create의 entity author는 새 entity에 기록하려는 ContentAuthorID다. update/delete의 entity
author는 현재 canonical projection에서 읽은 값이며 inbound payload로 덮어쓰지 않는다.

판정 실패는 fail-closed다. local command는 outbox/projection transaction을 시작하지 않고,
inbound reconcile은 projection/outbox/revision을 바꾸지 않는다. 실제 atomic no-mutation 검증은
HOT6-7이 소유한다.

### Matrix

| membership | verified actor = operation author | verified actor = entity author | decision | 이유 |
| --- | --- | --- | --- | --- |
| active Member | yes | yes | allow | 자신의 content mutation |
| active Owner | yes | yes | allow | Owner 자신의 content mutation |
| active Owner | yes | no | deny | Owner에게 다른 author content 우회 권한 없음 |
| active Member | yes | no | deny | content author mismatch |
| active Owner/Member | no | any | deny | operation author mismatch |
| Detached | any | any | deny | last snapshot read-only |
| non-member/removed | any | any | deny | active membership 없음 |

`TodoMateDomain/Tests/TodoMateDomainTests/Policy/ProjectMutationAuthorizationFixtures.swift`는
두 entry point × 세 resource × 세 mutation × 일곱 scenario의 126개 기대 decision을 생성한다.
local/inbound는 fixture metadata일 뿐 별도 권한 규칙이 아니다.

## Capability matrix

아래 표는 semantic input/output이다. 아직 Swift enum case나 transport operation 이름을 고정하지
않는다.

| 대상 | mutation | 승인 조건 | 명시적 거부 |
| --- | --- | --- | --- |
| Project settings | update | active Owner | Member, Detached, non-member |
| Membership | invite | active Owner의 서명 | Member가 만든 invite |
| Membership | kick | active Owner가 active Member를 target | Owner/self target, Member signer |
| Ownership transfer | request | current active Owner가 active Member를 target | Member signer, Owner/self target |
| Ownership transfer | accept | pending request의 정확한 target Member가 서명 | current Owner 또는 다른 Member의 accept |
| Membership | voluntary leave | 해당 active Member 본인이 서명 | current Owner의 leave |
| ChatChannel | create | 모든 active Owner/Member | Detached, non-member |
| ChatChannel name/topic | update | 해당 active Channel creator | creator가 아닌 Owner/Member, inactive creator |
| ChatChannel | archive/restore | active Owner | creator라는 이유만으로 archive/restore |
| Todo/Memo/Message | create/update/delete | 공통 content author matrix | Owner bypass |
| Detached copy | Todo/Memo | Detached actor가 자신이 쓴 content를 새 ID로 새 1인 Local Project에 복사 | 다른 author, ID reuse |
| Detached copy | Chat/Message | 없음 | 항상 거부; copy surface 자체를 제공하지 않음 |
| Shared Project | archive/delete | 없음 | MVP action surface 자체를 제공하지 않음 |

Detached snapshot read는 ProjectOperation mutation이 아니라 local read projection capability다.
제거된 identity는 새 subscription을 시작하지 않으며 마지막으로 검증된 local snapshot만 읽는다.

## Membership state machine

상태 이름 역시 semantic label이며 persistence enum이나 wire value가 아니다.

| current state | authenticated input | next state/effect | deny 또는 보류 |
| --- | --- | --- | --- |
| active Owner | transfer request(target Member) | transfer pending; Owner 유지 | target이 active Member가 아니면 deny |
| transfer pending | target Member acceptance | target가 Owner, 기존 Owner는 Member | 다른 signer acceptance deny |
| transfer pending | current Owner leave | 변화 없음 | acceptance 전 Owner leave deny |
| active Member | self-signed leave | membership removed, removed client Detached | 다른 identity가 만든 leave deny |
| active Owner | kick(active Member) | target membership removed, target client Detached | Owner/self target deny |
| removed/Detached | content/membership/channel write | 변화 없음 | 모든 원 Project write deny |
| removed/Detached | own Todo/Memo copy command | 새 1인 Local Project와 새 content ID | Chat/Message 또는 ID reuse deny |

transfer acceptance가 request보다 먼저 전달돼도 acceptance만으로 role을 바꾸지 않는다. Future
reconcile은 authenticated request와 acceptance가 모두 존재할 때 같은 accepted state를 만든다.
buffer/checkpoint의 실제 표현은 HOT6-7이 소유한다.

기존 Owner는 acceptance 뒤 Member가 된 다음에만 voluntary leave할 수 있다. transfer target이
acceptance 전에 leave하면 그 identity는 더 이상 active target이 아니므로 늦게 도착한 acceptance를
승인하지 않는다. 별도 cancel UX를 만들지는 이 계약의 범위가 아니다.

kick/leave commit은 다음 effect를 하나의 semantic boundary로 요구한다.

- 제거 identity의 새 local write, publish와 subscription 차단
- 제거 identity의 미승인 Project outbox 격리; 재전송 금지
- 제거 client의 마지막 검증 projection을 Detached read-only로 전환
- 남은 active Member용 새 Project key epoch 배포 시작

GRDB transaction, outbox state와 KeyEnvelope 조립은 HOT6-7/35가 구현한다.

## Conflict oracle

fixture의 event 이름은 symbolic input이다. EventID, revision DTO, timestamp와 schema column을
의미하지 않는다.

| fixture | delivery permutation 뒤 invariant | 현재 owner |
| --- | --- | --- |
| Todo different fields | 서로 다른 field 변경을 모두 보존 | HOT6-7 |
| Todo higher field revision | 높은 field revision을 선택 | HOT6-7 |
| Todo equal same-field revision | `requiresProductDecision(todoSameFieldTieBreaker)`; winner 없음 | HOT6-47 checkpoint |
| Memo whole document | 높은 revision을 current로 선택하고 진 본문을 conflict history에 보존 | HOT6-7 + HOT6-31/52 UI |
| Message creates | create를 append-only로 모두 보존 | HOT6-36/38 |
| ownership transfer | request/accept 전달 순서와 무관하게 두 인증 input 뒤 role 전환 | HOT6-7 |
| duplicate | 하나의 logical effect만 적용 | HOT6-7 |
| stale | current projection 유지 | HOT6-7 |
| unauthorized | projection과 outbox 변화 없음 | HOT6-7 |
| causally-after removal write | write 거부, removed identity outbox 격리 | HOT6-7/35 |

Memo conflict history는 별도 복제 Memo가 아니다. conflict version에는 원 revision의 본문과
author/provenance가 보존되며, 사용자의 restore는 current 본문을 덮어쓰지 않고 새 revision을
만든다.

Message edit/delete는 create append-only 규칙과 별개다. 작성자 서명 revision/tombstone만
승인하며 actual Message/Channel relation과 schema는 HOT6-36이 소유한다.

## Removal race의 순서 근거

전달 순서나 device wall clock만으로 removal/write 승자를 정하지 않는다.

- removal 전에 relay가 승인한 operation은 그 승인·causal evidence를 검증한 뒤 보존할 수 있다.
- 제거 client가 removal을 수신한 순간 아직 승인되지 않은 local outbox는 publish하지 않는다.
- removal에 causally dependent한 write는 전달이 뒤집혀 먼저 보이더라도 적용하지 않는다.
- future `ProjectOperation`/Relay contract는 이 구분에 필요한 authenticated ordering evidence를
  제공해야 한다. 정확한 field와 comparator는 HOT6-33/7이 정한다.

fixture의 `causallyAfterRemovalWrite`는 두 전달 순서 모두 reject/quarantine을 기대한다. 이는
모든 pre-removal write를 버리라는 뜻이 아니며, causal evidence가 없는 임의 wall-clock 추론을
금지하는 계약이다.

## Todo same-field checkpoint

아직 결정하지 않은 것은 동일 field, 동일 revision class에서의 최종 tie-breaker다.

- event ID만 비교
- author/device tuple 뒤 event ID 비교

fixture에는 comparator, `Comparable`, winner ID 또는 placeholder default를 넣지 않는다.
HOT6-33의 protocol DTO나 HOT6-26의 schema에 이 결정을 반영하기 직전에 사용자 review를 받아야
한다. 그 전까지 equal same-field fixture 결과는 반드시 `requiresProductDecision`이며 production
resolver가 임의 승자를 선택하면 안 된다.

## Producer·consumer handoff

| issue | 이 계약을 소비하는 책임 |
| --- | --- |
| HOT6-26 | typed Project/ContentAuthor ID와 Membership entity; author provenance 보존 |
| HOT6-33 | signed operation author, topic/cursor와 authenticated ordering input 계약 |
| HOT6-35 | removal 뒤 key epoch rotation과 KeyEnvelope runtime |
| HOT6-36 | ChatChannel creator/Owner capability와 Message author/tombstone Domain·schema |
| HOT6-7 | local/inbound 공통 authorization 호출, reconcile, GRDB no-mutation, outbox/removal permutation test |
| HOT6-38 | Message operation을 같은 SyncEngine/Relay path에 연결 |
| HOT6-31/52 | Memo Revision History conflict version과 restore-as-new-revision UI |
| HOT6-9 이후 Presentation | capability 결과만 소비; 역할 문자열로 control 노출을 추론하지 않음 |

TestSupport fixture는 production/Release dependency에 넣지 않는다. HOT6-26의
`TodoMateCoreTestSupport`가 생기면 이 test-only catalog를 해당 non-Release target으로 옮기되,
semantic scenario를 transport DTO나 GRDB seed로 바꾸지 않는다.

## 검증

이 slice의 증거 범위는 typed oracle 자체와 문서 handoff다.

```bash
just test-domain
just build
git diff --check
```

추가 scan은 다음을 확인한다.

- 새 production Domain source 없음
- fixture는 `TodoMateDomain/Tests` 아래에만 존재
- fixture와 문서에 GRDB/TCA/Nostr/Security/SwiftUI/AppKit import 없음
- Todo same-field comparator/winner/default 없음

`just test-domain` 성공은 authorization production wiring, GRDB no-mutation 또는 Sync permutation
성공을 뜻하지 않는다.
