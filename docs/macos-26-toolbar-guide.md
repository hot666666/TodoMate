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
