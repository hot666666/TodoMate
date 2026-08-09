# 01. Nostr — 시작 전에 알아야 할 것

> 목표: "Firestore를 쓰던 사람이 Nostr로 그룹 기능을 만들 때 반드시 알아야 하는 것"만 정리.
> Nostr 전반의 소개가 아니라 **TodoMate 구현에 필요한 지식**에 한정.

---

## 1. 세 줄 정의

| 개념   | Nostr                                                                           | Firebase 대응     |
| ------ | ------------------------------------------------------------------------------- | ----------------- |
| 계정   | secp256k1 키쌍. 공개키(pubkey) = 사용자 ID                                      | Firebase Auth uid |
| 데이터 | 서명된 불변 JSON 객체 = **이벤트(Event)**                                       | Firestore 문서    |
| 서버   | **릴레이(Relay)** = WebSocket 서버. 이벤트를 받아 저장하고, 구독자에게 흘려보냄 | Firestore         |

**릴레이에는 애플리케이션 로직이 없다.** 보안 규칙, 트랜잭션, 트리거, 집계 쿼리가 전부 없다. "서명이 유효한가"만 검증하고 저장한다. 나머지 규칙은 전부 클라이언트가 합의해서 지켜야 한다.

---

## 2. 이벤트 구조 (NIP-01)

모든 데이터는 이 형태다. 예외 없다.

```json
{
  "id": "<sha256 hex 32bytes>",
  "pubkey": "<작성자 공개키 hex 32bytes>",
  "created_at": 1754092800,
  "kind": 1,
  "tags": [
    ["e", "<event id>"],
    ["p", "<pubkey>"],
    ["d", "todomate:v1:todos:2026-08-02"]
  ],
  "content": "임의의 문자열",
  "sig": "<schnorr 서명 hex 64bytes>"
}
```

- `id` = `sha256(UTF8(JSON([0, pubkey, created_at, kind, tags, content])))`
  - **직렬화 규칙이 엄격하다.** 공백 없음, 키 순서 고정, 특정 이스케이프 규칙(`\n`, `\"`, `\\` 등). 여기서 1바이트만 달라도 다른 릴레이/클라이언트가 이벤트를 거부한다. 직접 구현 시 첫 번째 버그가 거의 항상 여기서 난다.
- `sig` = secp256k1 **Schnorr** 서명 (ECDSA 아님). `id`에 대해 서명.
- `content`는 그냥 문자열이다. 구조화된 데이터를 넣으려면 JSON을 문자열로 직렬화해서 넣는다.
- `created_at`은 **작성자가 임의로 넣는 값**이다. 신뢰할 수 없다. (→ 정렬/충돌 해결에서 중요, §8)

---

## 3. kind 범위 = 데이터 모델링의 핵심

kind 숫자 범위에 따라 **릴레이의 저장 동작이 달라진다.** 이게 Nostr 데이터 모델링의 전부라고 해도 과언이 아니다.

| 범위                          | 이름            | 릴레이 동작                                   | TodoMate에서 쓸 곳                 |
| ----------------------------- | --------------- | --------------------------------------------- | ---------------------------------- |
| `1000~9999`, `4~44`, `1`, `2` | **Regular**     | 전부 저장 (append-only)                       | 채팅 메시지                        |
| `10000~19999`, `0`, `3`       | **Replaceable** | `(pubkey, kind)`당 **최신 1개만** 유지        | 프로필(kind 0), 릴레이 목록(10002) |
| `20000~29999`                 | **Ephemeral**   | 저장 안 함, 중계만                            | 타이핑 표시 같은 것                |
| `30000~39999`                 | **Addressable** | `(pubkey, kind, d태그)`당 **최신 1개만** 유지 | 그룹 정의, 일별 Todo 스냅샷        |

**Addressable(구 parameterized replaceable)이 TodoMate의 주력이다.**
Nostr 이벤트는 원칙적으로 한 번 발행되면 수정되지 않는다.

Addressable은 이벤트를
수정하는 기능이 아니라, `(kind, pubkey, d)`를 **주소로 삼아 그 주소에 최신 이벤트
하나만 남기는 규칙**이다. 따라서 같은 주소로 새 이벤트를 발행하면 기존 이벤트를
대체할 수 있고, 일반 이벤트처럼 `id`가 매번 달라지는 데이터를 하나씩 쌓지 않아도
된다.

Replaceable이 `(pubkey, kind)`당 하나의 문서만 표현할 수 있다면, Addressable은
`d`를 이용해 같은 사용자가 같은 kind 아래 여러 문서를 독립적으로 가질 수 있다.
따라서 TodoMate가 같은 kind 아래 여러 문서를 각각 upsert하려면 Addressable이 사실상
유일한 표준 선택이다.

다만 “다시 발행하면 무조건 덮어쓴다”는 뜻은 아니다. 릴레이는 같은 주소의 이벤트 중
`created_at`이 더 최신인 것을 선택한다(같으면 `id` tie-break가 적용될 수 있다).<br>
오래된 기기의 이벤트가 늦게 도착하면 새 데이터를 되돌릴 수 있으므로, TodoMate는
발행 시 `created_at`과 content 안의 `updatedAt`을 일관되게 관리해야 한다.

```
kind:31700 + pubkey:<나> + d:"todomate:v1:todos:2026-08-02"
  → "내 2026-08-02 할 일 목록"을 가리키는 주소.
  → 같은 주소에 더 최신 이벤트를 발행하면 최신 목록으로 대체됨.
```

여기서 주소에 포함되는 것은 `kind`, 작성자의 `pubkey`, `d`뿐이다. `h`(그룹),
`date` 같은 다른 태그는 필터링과 문맥을 위한 메타데이터일 뿐 주소를 분리하지 않는다.
따라서 서로 다른 문서가 공존해야 한다면 그 구분값을 `d`에 넣어야 한다. 예를 들어
그룹별 일일 스냅샷이라면 다음처럼 그룹 ID까지 포함해야 한다.

```text
d:"todomate:v1:todos:<groupId>:2026-08-02"
```

이걸 `naddr`(NIP-19)로 인코딩하면 `kind + pubkey + d`를 담은 **공유 가능한 포인터**가
된다. `naddr`는 이벤트 본문을 복사하거나 보존하는 값이 아니며, 릴레이 힌트를 포함할
수 있어 수신자가 해당 주소의 최신 이벤트를 찾도록 돕는다. 따라서 naddr를 아는 것만으로
읽기 권한이 생기지는 않고, 이벤트가 어느 릴레이에 남아 있는지도 별도로 보장되지 않는다.

---

## 4. 태그 = 유일한 인덱스

```json
"tags": [["h", "<group id>"], ["d", "..."], ["p", "<pubkey>"], ["t", "todo"]]
```

- **단일 문자 태그(`a`~`z`, `A`~`Z`)만 릴레이가 인덱싱한다.** 즉 `#e`, `#p`, `#d`, `#h`로만 필터링할 수 있다.
- 여러 문자 태그(`["client", "TodoMate"]`)는 저장은 되지만 **쿼리할 수 없다.**
- 관례:
  - `e` = 참조하는 이벤트 id, `p` = 참조하는 pubkey
  - `d` = addressable 이벤트의 식별자
  - `h` = 그룹 id (NIP-29)
  - `t` = 해시태그

> **설계 원칙**: 나중에 content를 암호화하더라도 태그는 평문으로 남는다.
> → **쿼리에 필요한 값은 태그로, 내용은 content로.** 대신 태그는 릴레이 운영자에게 노출된다는 뜻이기도 하다.

---

## 5. 릴레이 통신 프로토콜

WebSocket 위에 JSON 배열을 주고받는다. 전부 이게 끝이다.

**클라이언트 → 릴레이**

| 메시지                                    | 의미                                |
| ----------------------------------------- | ----------------------------------- |
| `["EVENT", <event>]`                      | 이벤트 발행                         |
| `["REQ", <subId>, <filter>, <filter>...]` | 구독 시작 (저장된 것 + 이후 실시간) |
| `["CLOSE", <subId>]`                      | 구독 종료                           |
| `["AUTH", <event>]`                       | NIP-42 인증 응답                    |

**릴레이 → 클라이언트**

| 메시지                                      | 의미                                                                                         |
| ------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `["EVENT", <subId>, <event>]`               | 매칭된 이벤트 전달                                                                           |
| `["OK", <eventId>, true/false, "<reason>"]` | 발행 수락/거부 (`duplicate:`, `blocked:`, `rate-limited:`, `restricted:`, `invalid:` 접두어) |
| `["EOSE", <subId>]`                         | 저장분 전송 완료. **이후부터는 실시간 푸시**                                                 |
| `["CLOSED", <subId>, "<reason>"]`           | 구독이 릴레이에 의해 종료됨                                                                  |
| `["NOTICE", "<msg>"]`                       | 사람이 읽는 메시지                                                                           |

**필터(filter)**

```json
{
  "kinds": [31700],
  "authors": ["<pubkey1>", "<pubkey2>"],
  "#d": ["todomate:v1:todos:2026-08-02"],
  "since": 1754000000,
  "until": 1754200000,
  "limit": 100
}
```

- 필터 **내부**의 조건들은 AND, 필터 **간**에는 OR.
- 배열 안의 값들끼리는 OR (`authors` 중 하나라도 일치).
- **완전 일치만 된다.** 부분 문자열 검색, prefix 검색, 범위 비교(`>=`)가 없다. `since`/`until`은 `created_at`에만 적용된다.
- 정렬 지정 불가. 관례상 `created_at` 역순으로 오지만 보장 아님.
- **count 집계가 없다.** (NIP-45 COUNT는 선택적이고 지원 릴레이가 적음)
  → 현재 `fetchCount(query:)`, `fetchTodoCountUseCase`는 Nostr에서 그대로 옮길 수 없다. 로컬 계산으로 바꿔야 한다.

**`EOSE`가 중요한 이유**: `REQ`는 "쿼리 + 실시간 리스너"가 하나로 합쳐진 것이다. Firestore의 `getDocuments()`와 `addSnapshotListener()` 구분이 없다. `EOSE`가 그 경계선이다. → 지금의 `readAll(useCache:)` + `observeAll()` 이중 구조가 Nostr에서는 하나로 합쳐진다.

---

## 6. 릴레이는 데이터베이스가 아니다 ★

**이 문서에서 가장 중요한 절.** Firestore 사고방식에서 오는 오해를 전부 여기서 정리한다.

| 오해                     | 실제                                                                                                                                           |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 이벤트를 보내면 저장된다 | 릴레이가 거부할 수 있다. `OK` false 응답을 반드시 처리해야 한다. 여러 릴레이 중 일부만 성공하는 상태가 정상이다.                               |
| 저장된 이벤트는 남아있다 | **보존 보장 없음.** 공개 릴레이는 용량 확보를 위해 오래된 이벤트를 임의로 삭제한다. 알려진 kind만 저장하고 커스텀 kind는 버리는 릴레이도 많다. |
| 삭제할 수 있다           | **불가능.** kind 5(NIP-09)는 "삭제해 주세요"라는 *요청*일 뿐, 릴레이가 지킬 의무가 없고 다른 릴레이에는 원본이 남는다.                         |
| 수정할 수 있다           | 이벤트는 불변. Replaceable/Addressable kind로 **덮어쓰는 것만** 가능. Regular kind(채팅 등)는 수정 자체가 불가능하다.                          |
| 트랜잭션을 쓸 수 있다    | 없다. 현재 `joinGroup`/`leaveGroup`의 Firestore 트랜잭션(그룹 memberIds + user.groupId 동시 갱신)은 Nostr에서 재현 불가.                       |
| 서버가 권한을 강제한다   | 릴레이는 서명만 본다. "이 사용자는 이 그룹에 쓸 수 없다"를 강제하려면 **NIP-29 릴레이**를 쓰거나 릴레이에 커스텀 정책을 직접 구현해야 한다.    |
| 중복이 안 생긴다         | 같은 이벤트가 여러 릴레이에서 여러 번 온다. `id` 기준 dedup은 클라이언트 책임.                                                                 |

**결론**: 릴레이를 캐시/전송 계층으로 취급하고, 진실의 원천은 로컬(GRDB)에 둔다. 자체 릴레이를 운영해야 그나마 보존을 통제할 수 있다.

---

## 7. 암호화와 그룹

- **NIP-44 (v2)** — 두 키 사이의 암호화. secp256k1 ECDH → HKDF로 conversation key 유도 → ChaCha20 + HMAC-SHA256. 패딩으로 길이를 일부 숨김.
  - **제공하지 않는 것 (명세에 명시)**: forward secrecy 없음, post-compromise security 없음, 부인방지성(deniability) 없음. IP·타임스탬프·대략적 길이는 릴레이에 노출.
  - **그룹 암호화는 명세 범위 밖이다.** NIP-44는 1:1 전용.
- **NIP-59 (Gift Wrap)** — 메타데이터까지 숨기는 3중 포장(rumor → seal kind 13 → gift wrap kind 1059, 매번 새 임시키로 서명). 누가 누구에게 보냈는지도 가린다.
- **NIP-17 (Private DM)** — 위 둘을 조합한 실제 DM 규격 (kind 14 채팅, kind 1059로 포장). **그룹 초대(그룹 키 전달)에 이걸 쓴다.**
- **그룹 E2EE 방법은 두 가지뿐**
  1. **공유 대칭키 방식** — 그룹 전용 키쌍을 만들어 멤버에게 NIP-17로 배포. 구현 단순, 하지만 멤버 탈퇴 시 키 로테이션을 직접 해야 하고 키가 유출되면 과거 전체가 노출됨.
  2. **MLS 기반 (Marmot Protocol)** — 예전 NIP-EE(kind 443/444/445)는 명세에서 `unrecommended`로 표시되고 **Marmot Protocol(MIP-00~05)로 대체**됨. forward secrecy와 post-compromise security를 제공하지만, 구현체가 Rust(MDK)와 TypeScript(marmot-ts)뿐이고 **Swift 구현체가 없다.** 현 시점에서는 장기 옵션.

---

## 8. 시간·순서·충돌

- `created_at`은 클라이언트가 정하므로 **거짓말이 가능하고 기기 시계가 틀어질 수 있다.**
- 릴레이는 미래 시각 이벤트를 거부하기도 한다(보통 +몇 분 허용).
- 이벤트에는 전역 순서가 없다. 채팅 순서 = `created_at` 정렬 + tie-break로 `id` 사전순 (관례).
- Addressable 이벤트 대체 규칙: `created_at`이 큰 쪽이 이김. **같으면 `id`가 사전순으로 작은 쪽**이 이긴다(릴레이 구현별 차이 있음).

> TodoMate 함의: 지금 `SyncTodayTodosUseCase`의 last-write-wins는 도메인 필드 `updatedAt`을 기준으로 한다.
> Nostr로 가도 **`created_at`이 아니라 content 안의 `updatedAt`을 기준**으로 병합해야 일관성이 유지된다.
> 단, 릴레이의 addressable 대체 판정은 `created_at`으로 일어나므로 **둘을 같은 값으로 맞춰 발행**하는 게 안전하다.

---

## 9. 알아야 할 NIP 목록

읽는 순서 기준으로 정리. ★는 이 프로젝트에서 필수.

| NIP      | 제목                                   | 왜 필요한가                                                |
| -------- | -------------------------------------- | ---------------------------------------------------------- |
| ★ **01** | Basic protocol flow                    | 이벤트/필터/릴레이 메시지. 전부의 기반                     |
| ★ **19** | bech32 인코딩                          | `npub`/`nsec`/`naddr`. UI에 보여줄 ID 형식, 그룹 초대 링크 |
| ★ **11** | Relay Information Document             | 릴레이 지원 NIP·제한(최대 필터 수, 메시지 길이) 조회       |
| ★ **42** | AUTH                                   | 사설 릴레이 접근 제어. 그룹 데이터 보호에 필수             |
| ★ **44** | Encrypted Payloads v2                  | 암호화 기본기                                              |
| ★ **59** | Gift Wrap                              | 메타데이터 은닉 포장                                       |
| ★ **17** | Private Direct Messages                | 그룹 초대·키 배포 채널                                     |
| ★ **09** | Event Deletion Request                 | 삭제의 한계를 이해하기 위해                                |
| ★ **65** | Relay List Metadata (kind 10002)       | 멤버가 어느 릴레이를 쓰는지 발견                           |
| ★ **49** | Private Key Encryption (`ncryptsec`)   | 개인키 백업/내보내기 UX                                    |
| **29**   | Relay-based Groups                     | 그룹 모델 A안의 근거. kind 9/11, 9000~9022, 39000~39005    |
| **78**   | Application-specific Data (kind 30078) | 앱 전용 데이터의 표준 자리                                 |
| **51**   | Lists / Sets                           | 멤버 목록을 표준 방식으로 표현할 때                        |
| **46**   | Nostr Connect (원격 서명)              | 개인키를 앱에 두지 않는 로그인. 2단계 옵션                 |
| **06**   | BIP-39 니모닉 키 유도                  | 12단어 백업 UX                                             |
| **C7**   | Chats (kind 9)                         | 채팅 메시지 표준 kind                                      |
| **EE**   | MLS 기반 E2EE                          | `unrecommended`. Marmot Protocol을 대신 참조               |

원문: https://github.com/nostr-protocol/nips

---

## 10. Firestore ↔ Nostr 개념 대조표

| Firestore                                  | Nostr                                   | 비고                                   |
| ------------------------------------------ | --------------------------------------- | -------------------------------------- |
| 컬렉션                                     | kind                                    | 컬렉션이 아니라 "타입"에 가까움        |
| 문서 ID                                    | `d` 태그 (addressable) / `id` (regular) |                                        |
| 문서 필드                                  | `content`(JSON 문자열) + 태그           | 쿼리 대상만 태그로                     |
| `where(field, ==, x)`                      | `{"#tag": ["x"]}`                       | 단일 문자 태그만, 완전 일치만          |
| `where(field, in: [...])`                  | 필터 배열 값                            | 동일                                   |
| `orderBy`                                  | 없음                                    | 클라이언트 정렬                        |
| `limit`                                    | `limit`                                 | 초기 조회분에만 적용                   |
| `count()` 집계                             | 없음                                    | 로컬에서 세야 함                       |
| `getDocuments(source:.cache)`              | 없음                                    | 로컬 이벤트 캐시를 직접 만들어야 함    |
| `addSnapshotListener`                      | `REQ` (EOSE 이후)                       | 프로토콜 기본 기능                     |
| `documentChanges` (added/modified/removed) | `EVENT`만 존재                          | **modified/removed 개념이 없다**       |
| `runTransaction`                           | 없음                                    | 낙관적 동시성 + 클라이언트 합의로 대체 |
| Security Rules                             | NIP-42 + 릴레이 정책                    | 릴레이를 직접 짜야 함                  |
| Auth uid                                   | pubkey (hex 64자)                       |                                        |
| 오프라인 지속성                            | 직접 구현                               | 아웃박스 큐 필요                       |

---

## 11. Swift 생태계 현황 (2026-08 기준)

| 선택지                                                                        | 상태                                                                                             | 장점                                                                          | 단점                                                                                                                                                                             |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nostr-sdk-ios](https://github.com/nostr-sdk/nostr-sdk-ios)                   | MIT, 순수 Swift, macOS 14+/Swift 5.10+. 최신 태그 `0.3.0`(2025-02), 마지막 푸시 2026-01. 스타 50 | 순수 Swift, SPM 네이티브, 의존성 가벼움(secp256k1.swift, CryptoSwift, Bech32) | 릴리스 주기가 느리고 커뮤니티가 작다. 릴레이 풀 API 성숙도 확인 필요                                                                                                             |
| [nostr-sdk-swift](https://github.com/rust-nostr/nostr-sdk-swift) (rust-nostr) | MIT, UniFFI 바인딩. `0.44.7` / `0.45.0-alpha`. 2026-08-01 푸시. 본체(rust-nostr) 스타 661        | 기능 최다(NIP-29/44/59/17 등), 매우 활발                                      | **Rust 바이너리 xcframework** 의존. 앱 서명/공증, 빌드 파이프라인, 디버깅 난이도 상승                                                                                            |
| 직접 구현                                                                     | —                                                                                                | 의존성 0, 필요한 것만. 프로젝트 규칙("서드파티 도입은 사전 협의")에 부합      | 이벤트 직렬화·Schnorr·NIP-44·bech32를 직접 검증해야 함. secp256k1은 [swift-secp256k1](https://github.com/21-DOT-DEV/swift-secp256k1)(활발, 0.23.2)로 해결 가능하나 나머지는 직접 |

**참고**: 직접 구현 시 필요한 최소 부품은 ① Schnorr 서명(swift-secp256k1) ② 이벤트 직렬화/해시(Foundation) ③ bech32(~100줄) ④ WebSocket(`URLSessionWebSocketTask`, 네이티브) ⑤ NIP-44(ChaCha20 원형이 CryptoKit에 없어 별도 구현 필요 — 여기가 유일한 난관).
→ 채팅·피드만 평문으로 먼저 만든다면 ⑤ 없이 시작할 수 있다.

---

## 12. 손으로 직접 확인해보기

문서 100줄보다 이게 빠르다. [`nak`](https://github.com/fiatjaf/nak) CLI:

```bash
brew install nak      # 또는 go install github.com/fiatjaf/nak@latest

nak key generate                                   # 키 생성
nak key public <nsec>                              # 공개키 확인
nak event -k 1 -c "hello" --sec <nsec> wss://relay.damus.io   # 이벤트 발행
nak req -k 1 -a <pubkey> --limit 5 wss://relay.damus.io       # 조회
nak decode npub1...                                # bech32 디코드
```

로컬 릴레이를 띄워서 왕복을 확인하는 것이 Phase 0의 첫 작업이다 ([03-implementation-plan.md](03-implementation-plan.md) 참조).

---

## 다음

→ [02-architecture.md](02-architecture.md): 이 지식을 TodoMate 구조에 어떻게 적용할 것인가
</content>
