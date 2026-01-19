## 📋 Summary
Refactors `HomeView` to use MVVM architecture and implements SwiftData observation via Repository pattern.

## 🎯 Motivation
- Improve state management across tab switching in `HomeView`.
- Remove manual data fetching triggers in favor of reactive `AsyncStream`-based observation.
- Standardize Repository pattern usage for SwiftData.

## 🔧 Changes
- **Architecture**: Introduced `HomeViewModel`, `BoardViewModel`, `TodoCalendarViewModel`.
- **Domain**: Added `ObserveTodosUseCase`, `ObserveMemosUseCase` returning `AsyncStream`.
- **Data**: Implemented `observeTodos` / `observeMemos` in Repositories using `NotificationCenter` for `ModelContext` changes.
- **UI**: Updated `BoardView`, `CalendarView`, `Sidebar` to observe Stores/ViewModels.
- **Tests**: Updated Mocks and Tests to support async observation.

## 🧪 Testing
- Passed `just test-all` (Domain, Data, App Logic, Runtime UI Tests).
- Verified `BoardView` date filters and scroll persistence.
- Verified `CalendarView` navigation and data sync.
