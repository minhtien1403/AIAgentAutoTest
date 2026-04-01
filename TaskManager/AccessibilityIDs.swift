import Foundation

/// Centralized accessibility identifiers for UI tests and assistive automation.
enum AccessibilityIDs {

    enum AppHeader {
        static func container(context: String) -> String { "smartTask_appHeader_\(context)_container" }
        static func title(context: String) -> String { "smartTask_appHeader_\(context)_title" }
    }

    enum TaskList {
        static let screen = "smartTask_taskList_screen"
        static let customHeader = "smartTask_taskList_customHeader"
        static let headerTitle = "smartTask_taskList_headerTitle"
        static let tableView = "smartTask_taskList_tableView"
        static let searchBar = "smartTask_taskList_searchBar"
        static let addButton = "smartTask_taskList_addButton"
        static let floatingAddButton = "smartTask_taskList_floatingAddButton"
        static let filterButton = "smartTask_taskList_filterButton"
        static let categoriesButton = "smartTask_taskList_categoriesButton"
        static let categoryFilterButton = "smartTask_taskList_categoryFilterButton"
        static let emptyState = "smartTask_taskList_emptyState"
        static let emptyStateTitle = "smartTask_taskList_emptyState_title"
        static let emptyStateMessage = "smartTask_taskList_emptyState_message"
    }

    enum CategorySelect {
        static let screen = "smartTask_categorySelect_screen"
        static let backButton = "smartTask_categorySelect_backButton"
        static let tableView = "smartTask_categorySelect_tableView"
        static let rowNone = "smartTask_categorySelect_row_none"
        static func row(categoryId: UUID) -> String { "smartTask_categorySelect_row_\(categoryId.uuidString)" }
    }

    enum CategoryList {
        static let screen = "smartTask_categoryList_screen"
        static let backButton = "smartTask_categoryList_backButton"
        static let addButton = "smartTask_categoryList_addButton"
        static let tableView = "smartTask_categoryList_tableView"
        static func row(categoryId: UUID) -> String { "smartTask_categoryList_row_\(categoryId.uuidString)" }
        static let newCategoryAlert = "smartTask_categoryList_newCategoryAlert"
        static let newCategoryNameField = "smartTask_categoryList_newCategoryNameField"
        static let validationAlert = "smartTask_categoryList_validationAlert"
    }

    enum TaskCell {
        static func container(taskId: UUID) -> String { "smartTask_taskCell_\(taskId.uuidString)" }
        static func title(taskId: UUID) -> String { "smartTask_taskCell_title_\(taskId.uuidString)" }
        static func priorityBadge(taskId: UUID) -> String { "smartTask_taskCell_priorityBadge_\(taskId.uuidString)" }
        static func taskStatusBadge(taskId: UUID) -> String { "smartTask_taskCell_taskStatusBadge_\(taskId.uuidString)" }
        static func dueDate(taskId: UUID) -> String { "smartTask_taskCell_dueDate_\(taskId.uuidString)" }
        static func completeToggle(taskId: UUID) -> String { "smartTask_taskCell_completeToggle_\(taskId.uuidString)" }
        static func category(taskId: UUID) -> String { "smartTask_taskCell_category_\(taskId.uuidString)" }
    }

    enum TaskDetail {
        static let screen = "smartTask_taskDetail_screen"
        static let backButton = "smartTask_taskDetail_backButton"
        static let title = "smartTask_taskDetail_title"
        static let description = "smartTask_taskDetail_description"
        static let priority = "smartTask_taskDetail_priority"
        static let dueDate = "smartTask_taskDetail_dueDate"
        static let taskStatusBadge = "smartTask_taskDetail_taskStatusBadge"
        static let taskStatusChangeButton = "smartTask_taskDetail_taskStatusChangeButton"
        static let statusPickerAlert = "smartTask_taskDetail_statusPickerAlert"
        static let editButton = "smartTask_taskDetail_editButton"
        static let deleteButton = "smartTask_taskDetail_deleteButton"
        static let markCompleteButton = "smartTask_taskDetail_markCompleteButton"
        static let categoryLabel = "smartTask_taskDetail_categoryLabel"
        static let subtasksTable = "smartTask_taskDetail_subtasksTable"
        static let addSubtaskButton = "smartTask_taskDetail_addSubtaskButton"
        static func subtaskRow(subtaskId: UUID) -> String { "smartTask_taskDetail_subtaskRow_\(subtaskId.uuidString)" }
        static func subtaskToggle(subtaskId: UUID) -> String { "smartTask_taskDetail_subtaskToggle_\(subtaskId.uuidString)" }
    }

    enum CreateTask {
        static let screenCreate = "smartTask_taskForm_screen_create"
        static let screenEdit = "smartTask_taskForm_screen_edit"
        static let titleField = "smartTask_taskForm_titleField"
        static let descriptionField = "smartTask_taskForm_descriptionField"
        static let priorityControl = "smartTask_taskForm_priorityControl"
        static let dueDatePicker = "smartTask_taskForm_dueDatePicker"
        static let includeDueDateSwitch = "smartTask_taskForm_includeDueDateSwitch"
        static let clearDueDateButton = "smartTask_taskForm_clearDueDateButton"
        static let saveButton = "smartTask_taskForm_saveButton"
        static let cancelButton = "smartTask_taskForm_cancelButton"
        static let validationAlert = "smartTask_taskForm_validationAlert"
        static let categorySelectionRow = "smartTask_taskForm_categorySelectionRow"
        /// Grid slot index (0…41) for the month calendar; stable reading order (row-major).
        static func calendarDayCell(index: Int) -> String { "smartTask_taskForm_calendarDay_\(index)" }
    }

    enum DeleteConfirm {
        static let alert = "smartTask_deleteConfirm_alert"
        static let deleteAction = "smartTask_deleteConfirm_delete"
        static let cancelAction = "smartTask_deleteConfirm_cancel"
    }

    enum Filter {
        static let alert = "smartTask_filter_alert"
        static let categoryAlert = "smartTask_filter_categoryAlert"
    }

    enum TaskInputField {
        static func container(identifier: String) -> String { "smartTask_taskForm_field_\(identifier)_container" }
        static func textField(identifier: String) -> String { "smartTask_taskForm_field_\(identifier)_text" }
    }
}
