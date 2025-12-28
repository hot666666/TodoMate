---
description: Runtime Verification Feedback Loop
---

*빌드 통과 != 정상 동작**. 코드 수정 후 반드시 테스트로 검증해야 합니다.

### 검증 순서
1. 수정 완료 → 2. 테스트 실행 → 3. 테스트 통과 확인 → 4. 커밋

### UI/런타임 변경 검증
- `accessibilityIdentifier` 추가
- UI 테스트 작성 또는 수정
- 관련 테스트만 실행 (`-only-testing:` 옵션)

### 테스트 실패 시
오류 분석 → 원인 파악 → 수정 → 다시 테스트 실행 → 통과할 때까지 반복
