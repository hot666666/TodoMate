# feat/offline-first-sync 작업 회고

## 시간이 걸렸던 문제들

### 1. Firebase 초기화 타이밍 오류
**문제**: `@State private var dependencies = AppDependencies()`가 `AppDelegate.applicationWillFinishLaunching` 전에 실행되어 Firebase가 configure 되기 전에 Firestore에 접근 시도.

**원인**: macOS에서 SwiftUI 앱의 `@State` 프로퍼티 초기화가 AppDelegate보다 먼저 실행됨.

**해결**: `AppDependencies.init()`에서 직접 `FirebaseApp.configure()` 호출.

**교훈**: SwiftUI 앱 생명주기와 AppDelegate 생명주기의 실행 순서를 정확히 이해해야 함.

---

### 2. GoogleService-Info.plist 번들 누락
**문제**: 빌드 스크립트가 plist를 프로젝트 루트에만 복사하고, 앱 번들 리소스에는 포함하지 않음.

**원인**: 빌드 페이즈 순서 - ShellScript가 Sources 전에 실행되어 번들 폴더가 아직 존재하지 않음.

**해결**:
1. 빌드 페이즈 순서 변경 (ShellScript → Resources 후로 이동)
2. 스크립트에서 `BUILT_PRODUCTS_DIR/UNLOCALIZED_RESOURCES_FOLDER_PATH`로 복사 추가

**교훈**: 빌드 페이즈 순서가 중요. 리소스 복사 스크립트는 Resources 빌드 후에 실행해야 함.

---

### 3. UI 테스트 "does not have a process ID" 오류
**문제**: macOS UI 테스트에서 앱 프로세스를 찾지 못함.

**원인**: 앱이 Firebase 초기화 실패로 크래시 → 테스트 러너가 프로세스 연결 불가.

**해결**: 위의 Firebase/plist 문제 해결 후 자동으로 해소.

**교훈**: UI 테스트 실패 시 앱 자체의 런타임 오류를 먼저 확인해야 함.

---

### 4. authorized=true 자동 설정 로직 오해
**문제**: `linkWithCredential`에서 `authorized=true`를 자동 설정하는 코드 작성.

**원인**: 사용자의 요구사항을 잘못 이해. `authorized`는 관리자가 서버에서 설정하는 것.

**해결**: `authorized` 업데이트 코드 제거.

**교훈**: 비즈니스 로직의 의도를 명확히 파악해야 함. "누가 이 값을 설정하는가"를 확인 필수.

---

## 개선 포인트

### 프로세스 개선

| 항목 | 개선 방안 |
|------|-----------|
| **빌드 vs 런타임 검증** | 빌드 성공만으로 끝내지 말고, `just test` 또는 특정 UI 테스트로 런타임 동작 확인 |
| **테스트 효율화** | 전체 테스트 대신 `-only-testing:` 옵션으로 관련 테스트만 실행 |
| **오류 원인 분석** | UI 테스트 실패 시 테스트 코드보다 앱 자체의 크래시 로그 먼저 확인 |

### 코드 품질 개선 (Copilot 피드백 기반)

| 항목 | 내용 |
|------|------|
| **DI 패턴 일관성** | 모든 매니저에 의존성을 init으로 주입 (AuthManager에 Firestore 누락 수정) |
| **에러 처리** | Auth 성공 후 Firestore 실패 시 롤백 로직 필요 |
| **로깅** | `print` 대신 `OSLog` 기반 `Log` 유틸리티 사용 |
| **상태 업데이트 순서** | 네트워크 작업 전에 상태 먼저 업데이트하여 race condition 방지 |

---

## 향후 작업 시 체크리스트

- [ ] Firebase 관련 초기화는 반드시 configure() 후에 Firestore 접근
- [ ] 빌드 스크립트 변경 시 빌드 페이즈 순서 확인
- [ ] 코드 수정 후 빌드 + 런타임 테스트 모두 실행
- [ ] 테스트 실패 시 앱 크래시 로그부터 확인
- [ ] 비즈니스 로직 관련 플래그는 "누가 설정하는가" 확인
