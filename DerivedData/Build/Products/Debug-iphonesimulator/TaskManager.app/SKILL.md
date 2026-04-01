---
name: taskmanager-feature-development
description: Implements UIKit features in the TaskManager (SmartTask) iOS app following its MVVM layout, AppHeaderView, AccessibilityIDs, and Core Data patterns. Use when adding screens, flows, models, repositories, or UI that must match this project’s existing conventions.
---

# TaskManager — new feature development

## Before coding

1. Read the closest existing feature (same screen type: list / detail / form) and mirror its structure.
2. Place files in the folders below; do not introduce new top-level patterns without a strong reason.

## Project layout

| Area | Path | Role |
|------|------|------|
| Domain models | `Models/` | Value types (`struct`, `enum`): `Sendable`, `Equatable`/`Identifiable` as needed |
| View models | `ViewModels/` | `@MainActor` `final class`; depends on `TaskRepositoryProtocol` (or new protocols) |
| Screens | `ViewControllers/<Feature>/` | `UIViewController` subclasses, programmatic UI |
| Reusable UI | `Views/` | Cells, headers, inputs, badges |
| Persistence | `Repository/` | Core Data mapping (`TaskEntity+Mapping`), `TaskRepository` |
| App services | `Services/` | e.g. `StorageService` — `NSPersistentContainer` named `SmartTask` |

## Architecture conventions

- **MVVM**: View controllers bind to a dedicated ViewModel. Business rules and repository calls live in the ViewModel, not scattered in the VC.
- **Repository**: Define a protocol (e.g. `TaskRepositoryProtocol`) for fetch/save/delete; `TaskRepository` uses `StorageService.shared.viewContext` by default.
- **Domain vs Core Data**: `Task` (and similar) are plain structs. Map `TaskEntity` ↔ domain in `TaskEntity+Mapping.swift` (`toDomain()`, `update(from:)`).
- **UIKit**: Programmatic layout (`translatesAutoresizingMaskIntoConstraints = false`), Auto Layout. Prefer `UIStackView` for vertical forms. Table: `UITableView` with `.insetGrouped` where the list already uses it.

## View controller patterns

- `final class`, `init(nibName: nil, bundle: nil)`, `required init?(coder:)` → `fatalError("init(coder:) has not been implemented")`.
- **Navigation bar**: `navigationController?.setNavigationBarHidden(true, animated:)` in `viewWillAppear` when using `AppHeaderView`.
- **Background**: `view.backgroundColor = .systemGroupedBackground` for main screens.
- **Custom header**: Use `AppHeaderView(title:containerAccessibilityIdentifier:titleAccessibilityIdentifier:)`, add to view, then `pinAppHeaderToTopSafeArea(_:)` (extension on `UIViewController` in `AppHeaderView.swift`). Content anchors to `appHeaderView.bottomAnchor`.
- **Navigation**: Push with `UINavigationController`; pass `repository` and completion closures that `popViewController` and `refresh` the parent when needed. Use `[weak self]` in closures.
- **Actions**: Prefer `UIAction` or `@objc` selectors consistent with neighboring code.

## ViewModels

- Mark `final class` with `@MainActor`.
- Inject `TaskRepositoryProtocol` (not the concrete type unless unavoidable).
- Expose validation and `throws` for save flows; map user-facing errors to alerts in the VC.

## Accessibility and automation

- Add identifiers in `AccessibilityIDs.swift` only. Prefix pattern: `smartTask_<area>_<element>`.
- Nested enums per screen (`TaskList`, `TaskDetail`, `CreateTask`, etc.). Dynamic IDs use `UUID` or `context` strings (see `AppHeader`, `TaskCell`).
- Set `view.accessibilityIdentifier` for screens; `accessibilityLabel` on interactive controls; `alert.view.accessibilityIdentifier` for `UIAlertController` when present.

## Data changes

- **New fields on Task**: Update `Task` model, `TaskEntity` + Core Data model if needed, `TaskEntity+Mapping`, `TaskRepository` methods, and any ViewModels/UI.
- **Sorting/filtering**: Follow `TaskListViewModel` (local `displayedTasks` derived from `tasks` + filter + search).

## Reusable components (prefer these)

- `AppHeaderView` — titles and icon buttons; reuse `AccessibilityIDs.AppHeader` with a distinct `context` string per screen.
- `TaskInputField`, `DescriptionTextInputContainer`, `SimpleDatePickerView`, `EmptyStateView`, `PriorityBadgeView` when appropriate.

## App entry

- Root stack is built in `SceneDelegate` (`TaskRepository` → `TaskListViewController`). New root flows or deep links change here.

## Checklist for a new screen

- [ ] ViewModel + VC in the folders above; no duplicate business logic in the VC.
- [ ] `AccessibilityIDs` entries added; header uses `AppHeader` context string.
- [ ] Repository/protocol updated if persistence changes; mapping file updated.
- [ ] Matches typography (`.preferredFont(forTextStyle:)`), grouped background, and existing navigation patterns.

## Additional resources

- For iOS Simulator automation and builds, see the user’s `ios-simulator-skill` if attached.
