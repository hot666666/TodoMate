# Deferred RelayLive / Nostr 연구

> [!WARNING]
> 이 디렉터리는 2026-08-02 시점의 과거 연구 snapshot이다. NIP-29 우선 phase plan, GCP Relay
> 운영, E2EE 후순위, raw `nsec` import와 personal/group 분리는 폐기된 가정이다. 현재 구현
> 순서나 MVP 완료 gate로 사용하지 않는다.

현재 제품·실행 기준은 다음 문서다.

- [TodoMate Future Core Architecture v0.2](https://linear.app/hot6/document/todomate-future-core-architecture-v02-05b1682c21b0)
- [TodoMate Project-first Full Mock Client MVP](https://linear.app/hot6/document/todomate-project-first-full-mock-client-mvp-f46148c475f5)
- [TodoMate MVP Execution & Evidence Policy](https://linear.app/hot6/document/todomate-mvp-execution-and-evidence-policy-6e70dadd7d09)
- [`docs/app-architecture.md`](../app-architecture.md)

## 현재 persistence 구현 경계

HOT6-5/6 migration은 legacy 개인 Todo·Memo·휴지통을 App Group 단일 GRDB로 옮긴다. 앱은
read-write migration/import를 소유하고 Widget은 schema-validated read-only query만 사용한다.
Bundle ID는 기존 `io.hotcs6.TodoMate[Debug]`를 유지하고 canonical App Group만
`group.io.hotcs6.TodoMate[Debug]` 등록형으로 전환한다. 전환 build는 legacy Team-ID group을
함께 허용하며, 앱의 검증된 backup migration이 끝날 때까지 Widget은 legacy DB를 read-only로
fallback한다.
`localRevision`과 `deletedAt`은 로컬 메타데이터이며 DB change notification은 UI invalidation
신호일 뿐 durable sync outbox가 아니다. 이는 Project schema, `SyncEngine` 또는 `RelayLive`
구현 완료를 뜻하지 않는다.

## 현재 계약

- Product Project가 개인·공유 사용의 단일 aggregate다.
- Todo, Memo, 다중 Channel Chat은 RelayBinding 없이 local-only로 동작한다.
- GRDB가 client canonical source이며 durable outbox는 local mutation과 함께 commit한다.
- 공유는 adapter-neutral `RelayClient`와 production-shaped `MockRelayClient`로 MVP를 검증한다.
- identity private key는 Keychain에만 둔다. 정식 공유 operation은 처음부터 E2EE다.
- encrypted recovery file과 QR은 같은 identity payload이며 raw `nsec` QR은 제공하지 않는다.
- Owner/Member membership 권한은 다른 작성자의 content mutation 권한을 주지 않는다.
- kick/leave는 Project key epoch를 회전하고 제거된 client를 Detached read-only로 남긴다.
- Live Relay server, WebSocket adapter, migration, 운영과 archive는 후속 범위이며 Full Mock
  client MVP를 막지 않는다.

## 이 디렉터리에서 여전히 유효한 것

| 문서 | 과거 연구 가치 | 현재 상태 |
| --- | --- | --- |
| [01-nostr-primer.md](01-nostr-primer.md) | protocol/event/kind 배경 | 참고 자료 |
| [02-architecture.md](02-architecture.md) | 초기 NIP mapping과 위험 분석 | 폐기된 architecture |
| [03-implementation-plan.md](03-implementation-plan.md) | 초기 phase 산정 | 폐기된 실행 계획 |
| [04-open-questions.md](04-open-questions.md) | 2026-08-02 decision history | 폐기된 결정 |
| [05-relay-operations.md](05-relay-operations.md) | 향후 operation 후보 연구 | Deferred RelayLive 작업 |

이 디렉터리의 과거 Relay spike나 phase 순서를 시작하지 않는다. 현재 작업은 dependency
frontier에 따라 Core/SPM 계약 이후 Presentation/UI, Local Domain, Mock Sync/E2EE를 병렬로
진행하고 Full Mock과 POM/Screenshot 통합에서 합친다.
