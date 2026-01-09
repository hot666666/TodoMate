---
description: 이 프로젝트는 **Test-Driven Development (TDD)**를 기반으로 코드의 안정성과 품질을 보장합니다. 에이전트(AI)가 개발을 진행하더라도 테스트를 통해 구현의 정확성을 검증하고, 회귀 버그를 방지하며, 리팩토링의 안전성을 확보해야 합니다.
---

# Development Workflow

## Pre-flight Check (필수)

작업을 시작하기 전에 반드시 다음을 확인합니다:

```bash
git status
git log --oneline -5
```

1. 현재 브랜치가 이미 머지 완료된 상태인지 확인합니다.
2. 해당 브랜치가 이미 완료/머지된 상태이고, 유저가 명시적으로 재작업을 요청하지 않았다면 **아무 작업도 진행하지 말고 종료**합니다.

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BASE_BRANCH` | 현재 브랜치 | 새 feat/fix 브랜치를 생성할 기준 브랜치. 다른 베이스가 필요하면 `BASE_BRANCH=main`처럼 명시합니다. |
| `USE_PR` | `false` | GitHub PR 워크플로우 사용 여부. `true`면 `.agent/workflows/gh-create-pr.md` 참조. |

---

## Prerequisites

1. `GEMINI.md`에서 **Target Platform / Test Device / Minimum Version** 같은 실행 환경 기준을 확인합니다.
2. `.agent/rules/project-rules.md`를 확인해 **Swift/SwiftUI 코딩 규칙**을 준수합니다.

---

## Branching Strategy

1. 모든 작업은 `BASE_BRANCH`에서 새 브랜치를 만들어 시작합니다.
2. 브랜치명 형식 (기존 브랜치 네이밍 참고):
   - `feat/<topic>` — 새로운 기능
   - `fix/<topic>` — 버그 수정
   - `refactor/<topic>` — 코드 리팩토링
   - `chore/<topic>` — 빌드, 설정 등 기타

---

## 0. Test Authoring (필수)

유저가 "검증 방법/테스트 범위"를 명시하지 않았다면, 구현 전에 최소한의 검증 기준을 테스트로 먼저 정의합니다.

### 테스트 작성 규칙

이미 작성된 테스트코드를 참고하면 어떤식으로 테스트 작성할 지 이해하기 쉽습니다.

- **Given-When-Then** 구조가 읽히도록 작성합니다.
- 검증에 쓸 값(문자열/ID/날짜)은 테스트 상단에 **변수로 선언**하고, `Then`에서 그 변수를 사용합니다(하드코딩 최소화).
- 신규 단위 테스트는 **Swift Testing** 우선 사용.
- UI Automation/성능 테스트는 **XCTest** 사용.

---

## Workflow Cycle: Red-Green-Refactor

### 1) Red: Failing Test 작성

**목표**: 예상 동작(acceptance)을 코드로 고정합니다.

**액션**:
- 로직/모델/서비스 동작이면 → **Unit Test**
- UI 레벨 동작이면 → **UI Test** (XCTest 기반)
- 테스트가 **실패함을 확인** (컴파일 실패 또는 assertion 실패)
- UI Test에 대해선 `docs/xctest-ui-test.md`에 관련해 디테일한 추가 내용 존재.

### 2) Green: 최소 구현으로 통과

**목표**: 테스트를 통과시키는 **최소한의 코드**만 추가합니다.

**액션**:
- 과설계/미래 대비 금지
- 변경 범위를 작게 유지
- 통과 확인 후 작은 단위로 커밋

### 3) Refactor: 구조 개선 (테스트는 Green 유지)

**목표**: 중복 제거, 가독성 향상, 불필요한 복잡도 제거

**액션**:
- 리팩토링 중에도 테스트는 **계속 통과해야 함**
- `.agent/rules/project-rules.md` 규칙 위반 없도록 정리

---

## 4) Verification: 완료 판정 기준

### Verification Source of Truth (우선순위)

구현 전/완료 판정 전, 검증 기준은 다음 우선순위로 식별:

1. 이 repo의 workflow 문서 (현재 파일 등)
2. 관련 이슈/PR의 acceptance criteria
3. 첨부된 테스트 플랜/체크리스트/수동 재현 절차/기대 결과

> **명시된 검증 방법이 있으면 그것을 1순위로 따르고, 임의로 대체하지 않습니다** (오너 승인 없이는 변경 금지).

### Implement to Satisfy Verification

- 자동화 가능한 기준 → 테스트(Unit/Integration/UI)로 인코딩하고 통과
- 자동화가 비현실적 → 재현 가능한 수동 검증 절차 문서화 (환경/계정/데이터/steps/expected results)

### Definition of Done

다음이 **모두 충족**되어야 "done":

- [ ] Acceptance criteria가 테스트 또는 재현 가능한 검증 절차로 커버됨 (가능하면 테스트 우선)
- [ ] 변경된 코드 경로의 **실패 케이스** 고려됨 (에러/빈 상태/권한/네트워크/동기화/저장 등)
- [ ] 영향 범위 기준의 테스트가 통과함
  - 최소: 변경 컴포넌트 타겟 테스트
  - Merge 전: 팀 합의된 전체 테스트 세트

---

## Commands (justfile)

| 명령어 | 설명 | 에뮬레이터 |
|--------|------|:----------:|
| `just build` | 컴파일 검증 | ❌ |
| `just test` | 전체 테스트 | ❌ |
| `just test-unit` | Firebase 폴더 제외 유닛 테스트 | ❌ |
| `just test-firebase` | `TodoMateTests/Firebase` 테스트만 | ✅ |
| `just test-ui` | `TodoMateUITests` 테스트만 | ✅ |
| `just test-all` | 유닛 → Firebase → UI 순서로 실행 | ✅ |

### 영향 범위 기반 테스트

```bash
# 단일 타겟
just test-only TodoMateTests/CSVServiceTests

# 다중 타겟
just test-only-many TodoMateTests/CSVServiceTests TodoMateTests/ScheduleServiceTests
```

---

## 작업 흐름 요약

1. **브랜치 생성**: 관련된 네이밍으로 브랜치를 만들고 작업 수행
   - 기존 브랜치 네이밍 형식 참고 (예: `feat/`, `fix/`, `refactor/`)

2. **검증 계획**: 유저가 테스트 검증방안을 명시하지 않았다면, 어떻게 검증할지 먼저 생각

3. **구현 계획 수립**: `GEMINI.md` 참고하여 전체 작업 완료를 위한 계획 수립

4. **점진적 진행**: 계획의 부분들이 완료될 때마다 검증과 커밋 수행
   - 작업 중 검증: `just build`로 컴파일 문제 없음 확인
   - 작업 완료 후: 수정된 부분이 영향 미치는 곳들에 대한 테스트 수행

---

## Option: GitHub PR Workflow (USE_PR=true)

`USE_PR=true`인 경우 PR 워크플로우를 따릅니다.

**참고**: `.agent/workflows/gh-create-pr.md`

```bash
git push origin <feature-branch>
# PR 생성/리뷰/원격 squash merge 완료
```

---

## Pre-commit Hooks 참고

이 프로젝트는 pre-commit hooks를 사용합니다:

1. **SwiftFormat**: 코드 포맷팅 규칙 강제
2. **SwiftLint**: 코딩 스타일 위반 검사

커밋 실패 시 자동 수정:
```bash
swiftformat .
swiftlint --config .swiftlint.yml --fix
```

> **Warning**: Hook이 파일을 수정하면 해당 파일이 **UNSTAGED** 상태가 되어 커밋 실패. `git add .` 후 재시도 필요.
