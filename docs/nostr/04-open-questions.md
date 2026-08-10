# 04. 결정 사항 및 남은 질문

> [!WARNING]
> 2026-08-02의 과거 결정 기록이다. 현재 제품 결정이 아니며 [`README.md`](README.md)와
> canonical Project-first architecture를 따른다.

**결정 완료: 2026-08-02.** 아래 4가지가 확정되어 [02-architecture.md](02-architecture.md)와 [03-implementation-plan.md](03-implementation-plan.md)에 반영되었다.

---

## ✅ 확정된 결정

| # | 항목 | 결정 | 영향 |
|---|---|---|---|
| **D1** | 그룹 모델 | **A안 — NIP-29 릴레이 관리형** | 멤버십·초대·강퇴를 릴레이가 처리. `createGroup`/`joinGroup`/`leaveGroup`/`memberIds`가 kind 9007/9021/9022/39002로 거의 1:1 매핑. Phase 3 작업량 최소 |
| **D2** | 릴레이 | **자체 운영(GCP e2-micro 무료 티어) + 공개 릴레이 병행** | 그룹 데이터는 자체 릴레이가 권위. 공개 릴레이는 프로필(kind 0)·릴레이 목록(kind 10002)만. → [05-relay-operations.md](05-relay-operations.md) |
| **D3** | 라이브러리 | **직접 구현 + `swift-secp256k1`만 도입** | `TodoMateNostr` 패키지를 직접 작성. Phase 1이 이 프로젝트에서 가장 긴 구간(2~3주)이 됨. NIP-44는 Phase 6로 미룸 |
| **D4** | 마이그레이션 | **클린 스타트** | uid↔npub 매핑·이중 쓰기 코드 불필요. Phase 7이 대폭 축소. 그룹 채팅 이력은 포기 |

**D2 보충 — 사용자 환경**: 이미 간단한 서버가 도는 GCP e2-micro(무료 티어) VM 보유.
→ 사양은 충분하지만 **월 1GB 이그레스 한도**와 **1GB RAM**이 실제 제약이다. 운영 설계는 [05-relay-operations.md](05-relay-operations.md)에서 다룬다. **strfry 대신 khatru29(Go)를 권장**하는 이유도 여기에 있다.

**D3 보충 — 직접 구현 범위**: `swift-secp256k1`(Schnorr 서명/ECDH)만 SPM 의존성으로 추가하고, 이벤트 직렬화·bech32·WebSocket 릴레이 풀은 직접 작성한다. WebSocket은 `URLSessionWebSocketTask`(네이티브)를 쓰므로 추가 의존성이 없다. NIP-44(ChaCha20이 CryptoKit에 없음)는 Phase 6로 미뤄, Phase 1~5는 암호화 구현 없이 진행한다.

**D4 보충**: 개인 Todo/Memo는 이미 GRDB에 있어 추가 이관 대상이 아니다. 실제로 포기하는 것은 **기존 그룹 채팅 이력**뿐이다. 전환 시 사용자에게 안내 UI가 필요하다.

---

## 남은 질문

아래는 진행하면서 정해도 되는 항목. 각 항목의 **기본값**대로 문서가 작성되어 있다.

## Q5. 프라이버시 목표 수준

- 릴레이 운영자(나)가 그룹 채팅과 할 일을 볼 수 있어도 되는가?
- 된다면 → Phase 6(E2EE)은 후순위 또는 생략.
- 안 된다면 → Phase 6가 필수이고, 태그로 남는 메타데이터(누가/언제/어느 그룹)까지 숨길지도 정해야 한다. 완전 은닉(NIP-59 gift wrap을 그룹 이벤트에 적용)은 필터링이 불가능해져 전부 받아서 복호화해야 하는데, **소규모 그룹이면 실제로 감당 가능하다.**

**기본값**: Phase 1~5는 평문, Phase 6에서 content 암호화. 메타데이터 은닉은 하지 않음.

---

## Q6. 키 관리 UX 범위

- **iCloud Keychain 동기화를 허용할 것인가?**
  - 허용: 내 기기 간 자동 로그인, UX 최상. 대신 Apple이 키를 (암호화된 상태로) 갖게 됨
  - 비허용: 기기마다 `nsec` 수동 입력. 안전하지만 번거로움
- 백업 방식: NIP-49 `ncryptsec` 파일만? BIP-39 니모닉 12단어도?
- NIP-46(원격 서명, bunker) 지원은 범위에 넣는가? → **기본값: 제외** (`Signer` 프로토콜로 확장 여지만 확보)

**기본값**: 기기 한정 Keychain + `ncryptsec` 내보내기. iCloud 동기화는 설정에서 선택.

---

## Q7. 기능 범위 조정

Nostr 전환을 계기로 정리할지 결정할 것들:

| 항목 | 현재 | 제안 |
|---|---|---|
| 채팅 메시지 수정 | `MessageRepository.update` 존재하나 **UI 미사용** | 폐기 (Nostr에서 재현 불가) |
| 원격 카운트 집계 | `fetchCount` (Firestore 집계) | 로컬 계산으로 이전 |
| `UserRepository.readAll(useCache:)` (전체 사용자) | 존재 | 프로토콜에서 제거 (Nostr에 대응 없음) |
| 다중 그룹 | 1인 1그룹 (`User.groupId` 단일) | 유지? 확장? — 확장 시 스냅샷 `d` 태그 규칙이 바뀐다 (§02-5.3) |
| 원격 메모 | `MemoRepositoryImpl`은 있으나 **`PublicDIContainer`에 미등록** | 그룹 메모 공유 계획이 있는지 확인 필요 |
| 그룹 피드 실시간 | `observeTodos`가 빈 스트림 | Nostr에서 실제 구현 (개선) |

---

## Q8. 일정·릴리스

- Phase 0~7 전체는 실질적으로 몇 주~수개월 규모다. 한 번에 갈 것인가, Phase별로 릴리스할 것인가?
- 전환 중에도 기존 Firebase 그룹 기능이 계속 동작해야 하는가?
- 앱 스토어 배포 중인 버전에 영향을 주는가? (Sparkle 자동 업데이트 사용 중)

**기본값**: `dev` 브랜치에서 Phase별 머지, Firebase 경로는 Phase 7까지 살려둠.

---

## 다음 액션

D1~D4가 확정되었으므로 **[03-implementation-plan.md](03-implementation-plan.md)의 Phase 0(검증 Spike)** 착수가 가능하다.
Q5~Q8은 각각 Phase 6 / Phase 2 / Phase 3~5 / Phase 7 착수 직전까지만 정하면 된다.
