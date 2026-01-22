# macOS 26 Toolbar & Layout Guide

macOS 26 (WWDC25)에서 도입된 새로운 Toolbar API와 레이아웃 전략에 대한 가이드입니다.

## 1. 주요 변경 사항: `ToolbarSpacer`

이전 macOS 버전에서는 `Spacer()`를 ToolbarItem 내부에 넣거나 빈 뷰를 사용하여 간격을 조절해야 했으나, macOS 26부터는 명시적인 `ToolbarSpacer` API가 도입되었습니다.

### ToolbarSpacer 종류
- **`.fixed`**: 고정된 크기의 간격을 제공합니다. (기본값)
- **`.flexible`**: 가능한 공간을 모두 차지하여 아이템들을 양쪽 끝으로 밀어냅니다.

## 2. Toolbar Item 배치 전략

아이템들을 원하는 순서와 간격으로 배치하기 위해서는 `ToolbarItemGroup` 대신 개별 `ToolbarItem`과 `ToolbarSpacer`를 조합하여 사용하는 것이 권장됩니다.

### ⛔️ `ToolbarItemGroup` 사용 시 주의사항
`ToolbarItemGroup` 내부에 여러 아이템을 넣으면, macOS 표준 간격으로 자동 그룹화되며 커스텀 `Spacer`가 의도한 대로 동작하지 않을 수 있습니다. 특히 `ToolbarSpacer`는 `View`가 아닌 `ToolbarContent`이므로 Group 내부가 아닌 형제 레벨에 배치되어야 합니다.

### ✅ 권장 패턴: Sibling Items + Flexible Spacer

원하는 레이아웃(예: `[Left Items] ---- [Center Items] ---- [Right Items]`)을 구현하려면 다음과 같이 구성합니다.

```swift
@ToolbarContentBuilder
private var toolbarContent: some ToolbarContent {
    // 1. 왼쪽 아이템
    ToolbarItem(placement: .primaryAction) {
        Button(...)
    }

    // 2. 가변 간격 (왼쪽과 중앙 사이 벌리기)
    ToolbarSpacer(.flexible)

    // 3. 중앙/오른쪽 아이템 그룹
    if hasSelection {
        ToolbarItem(placement: .primaryAction) { Button(...) }
        ToolbarItem(placement: .primaryAction) { Button(...) }

        // 4. 아이템 사이 간격 (필요시)
        ToolbarSpacer(.flexible)
    }

    // 5. 오른쪽 끝 아이템
    ToolbarItem(placement: .primaryAction) {
        Menu(...)
    }
}
```

## 3. 실전 예제 (DeletedItemsView)

**요구사항**: `[전체 선택] --------- [복구] [삭제] --------- [정렬]`

```swift
@ToolbarContentBuilder
private var toolbarContent: some ToolbarContent {
    // 1. 맨 왼쪽 (전체 선택)
    ToolbarItem(placement: .primaryAction) {
        selectAllButton
    }

    // 2. 간격 벌리기 (Flexible)
    ToolbarSpacer(.flexible)

    // 3. 중앙 (조건부 표시: 복구/삭제)
    if viewModel.hasSelection {
        ToolbarItem(placement: .primaryAction) {
            restoreButton
        }
        ToolbarItem(placement: .primaryAction) {
            deleteButton
        }

        // 4. 간격 벌리기 (Flexible) -> 오른쪽 정렬 메뉴를 끝으로 밀어냄
        ToolbarSpacer(.flexible)
    }

    // 5. 맨 오른쪽 (정렬)
    ToolbarItem(placement: .primaryAction) {
        sortMenu
    }
}
```

## 4. 요약
1. **`ToolbarSpacer(.flexible)`**을 사용하여 정렬과 배치를 제어한다.
2. `ToolbarItemGroup` 보다는 개별 **`ToolbarItem`**을 나열하여 순서를 명확히 제어한다.
3. `Divider()`는 macOS Toolbar에서 시각적 분리 역할을 제대로 수행하지 못하므로, 간격이 필요하면 `ToolbarSpacer`를 사용한다.

## 5. Toolbar Item Placement 가이드

`ToolbarItem(placement: ...)`을 사용하여 아이템의 의미론적 위치를 지정할 수 있습니다. macOS에서는 이 placement가 시각적 위치를 결정하는 데 중요한 역할을 합니다.

### 5.1 주요 Placement 옵션

| Placement | 설명 | macOS 위치 |
| :--- | :--- | :--- |
| **`.navigation`** | 네비게이션 관련 동작 (뒤로가기, 사이드바 토글 등) | **왼쪽 (Leading)**. 타이틀 영역보다 왼쪽에 배치됩니다. |
| **`.primaryAction`** | 뷰의 주요 동작 (추가, 편집, 저장 등) | **오른쪽 (Trailing)**. 주로 서치바 옆이나 윈도우 우측 상단에 배치됩니다. |
| **`.principal`** | 현재 컨텍스트의 핵심 정보 또는 컨트롤 | **중앙 (Center)**. 윈도우 타이틀 영역의 중앙에 위치합니다. |
| **`.automatic`** | 시스템이 문맥에 따라 자동으로 결정 | 위치가 유동적일 수 있으므로 명시적 배치를 권장합니다. |
| **`.status`** | 상태 정보 표시 | UI 일관성을 위해 신중히 사용해야 합니다. |

### 5.2 Modal/Sheet 전용 Placement

| Placement | 설명 | macOS 위치 |
| :--- | :--- | :--- |
| **`.cancellationAction`** | 작업 취소 (Cancel, 닫기) | **왼쪽 (Leading)** |
| **`.confirmationAction`** | 작업 완료/확인 (Done, Save, Add) | **오른쪽 (Trailing)**. 강조된 스타일(Accent Color)이 적용될 수 있습니다. |

### 5.3 💡 Tip: `.navigation` vs `.primaryAction`

사용자가 언급한 것처럼 `.navigation`을 사용하면 **확실하게 왼쪽 영역**을 선점할 수 있습니다.
- **왼쪽 배치**: `ToolbarItem(placement: .navigation)`
- **오른쪽 배치**: `ToolbarItem(placement: .primaryAction)`

중간에 `ToolbarSpacer()`를 사용하는 전략과 함께, `placement`를 명시적으로 지정하면 더욱 견고한 레이아웃을 만들 수 있습니다.
