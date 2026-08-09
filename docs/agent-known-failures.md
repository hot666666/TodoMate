# 에이전트 반복 실패 런북

반복되는 개발·검증 환경 실패를 짧고 실행 가능한 형태로 기록합니다. 이 문서는 원시 로그
보관소나 일회성 오류 목록이 아닙니다.

## 기록 기준

다음 중 하나에 해당할 때만 항목을 추가합니다.

- 같은 원인으로 두 번 이상 재발했다.
- 원인을 모르면 재현·복구에 상당한 시간이 든다.
- 저장소의 표준 명령, 개발 환경, CI, 외부 에뮬레이터 설정과 직접 관련 있다.

구현 버그는 먼저 GitHub Issue와 테스트로 관리합니다. 개인 토큰·로컬 경로·개인 정보·원시
로그는 이 문서에 기록하지 않습니다.

## 항목 형식

```md
## 짧은 증상 제목

- 증상: 사용자가 보는 오류 또는 실패한 명령
- 재현 조건: 어떤 변경·환경·순서에서 발생하는지
- 확인된 원인: 추정이 아닌 확인된 원인만 작성
- 해결 또는 우회: 안전한 순서와 필요한 명령
- 검증: 해결을 확인하는 명령 또는 관찰 결과
- 관련: GitHub Issue, PR, 공식 문서 링크
- 제거 조건: 도구·설정·코드가 바뀌어 더 이상 유효하지 않은 시점
```

## 관리 원칙

- 해결 방법이 바뀌면 기존 항목을 갱신합니다. 같은 문제를 새 항목으로 중복 기록하지
  않습니다.
- 해결되어 더 이상 재발할 수 없으면 항목을 제거합니다.
- 각 항목은 필요한 정보만 포함하고, 긴 명령 출력은 CI 아티팩트나 GitHub Issue에 둡니다.
- 추정과 확인된 사실을 섞지 않습니다. 원인이 불명확하면 Issue 링크만 남기고 확정된
  조치가 생긴 뒤 기록합니다.

## macOS UI 테스트가 automation mode 진입 전에 시간 초과

- 증상: `just test-app-runtime`이 앱과 UI test runner를 빌드한 뒤 약 60초 동안 테스트를
  시작하지 못하고 `Timed out while enabling automation mode`로 실패한다.
- 재현 조건: macOS destination에서 `TodoMateUITests`를 실행할 때 같은 checkout에서 두 번
  연속 재현됐다. 두 실행 모두 Test Suite 또는 Test Case가 한 건도 시작되지 않았다.
- 확인된 원인: XCTest UI test runner가 automation mode를 활성화하지 못해 초기화 단계에서
  종료됐다. 제품 테스트 실패나 앱 assertion 실패는 관찰되지 않았다. 더 하위의 환경 원인은
  아직 확인되지 않았다.
- 해결 또는 우회: 한 번만 재시도해 일시적 실패인지 확인한다. 같은 초기화 오류가 반복되면
  제품 코드를 임의로 수정하지 않고 환경 검증 blocker로 기록하며 해당 `.xcresult`를 보존한다.
- 검증: automation mode가 정상화된 환경에서 `just test-app-runtime`을 다시 실행해 실제 Test
  Suite와 Test Case가 시작되고 명령이 종료 코드 0으로 끝나는지 확인한다.
- 관련: `HOT6-6`; `just test-app-runtime`
- 제거 조건: 저장소의 test recipe 또는 CI runner가 automation mode를 결정론적으로 준비하고
  같은 오류가 더 이상 재현되지 않을 때 제거한다.

## macOS App 단위 테스트 host가 시작되지 않음

- 증상: `just test-app`이 clean build와 signing을 마친 뒤 Test Suite 또는 Test Case를 시작하지
  못한 채 대기한다. 중단 시 진단에는 `waiting for workers to materialize`,
  `IDEInstallLocalMacWorker`, `IDELaunchServicesLauncher`가 나타난다.
- 재현 조건: repository 내부와 `/tmp`의 서로 다른 DerivedData에서 `xcodebuild test` 및
  `test-without-building`으로 반복됐다. 같은 checkout의 더 이른 clean 실행에서는 13개 테스트가
  모두 통과했으므로 코드 assertion의 결정론적 실패로 분류할 수 없다.
- 확인된 원인: XCTest가 local macOS test host를 materialize하고 LaunchServices로 실행하는 단계가
  완료되지 않았다. 더 하위의 환경 원인은 아직 확인되지 않았다.
- 해결 또는 우회: 한 번만 clean DerivedData로 재시도한다. 같은 worker 초기화 오류가 반복되면
  실행을 중단하고 `.xcresult`를 보존하며 제품 테스트 실패로 기록하지 않는다.
- 검증: test host가 정상화된 환경에서 `just test-app`을 다시 실행해 실제 Test Suite와 13개 Test
  Case가 시작되고 명령이 종료 코드 0으로 끝나는지 확인한다.
- 관련: `HOT6-6`; `just test-app`
- 제거 조건: canonical test runner가 local worker와 test host를 결정론적으로 준비하고 같은 오류가
  더 이상 재현되지 않을 때 제거한다.
