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
        static let emptyState = "smartTask_taskList_emptyState"
        static let emptyStateTitle = "smartTask_taskList_emptyState_title"
        static let emptyStateMessage = "smartTask_taskList_emptyState_message"
    }

    enum TaskCell {
        static func container(taskId: UUID) -> String { "smartTask_taskCell_\(taskId.uuidString)" }
        static func title(taskId: UUID) -> String { "smartTask_taskCell_title_\(taskId.uuidString)" }
        static func priorityBadge(taskId: UUID) -> String { "smartTask_taskCell_priorityBadge_\(taskId.uuidString)" }
        static func dueDate(taskId: UUID) -> String { "smartTask_taskCell_dueDate_\(taskId.uuidString)" }
        static func completeToggle(taskId: UUID) -> String { "smartTask_taskCell_completeToggle_\(taskId.uuidString)" }
    }

    enum TaskDetail {
        static let screen = "smartTask_taskDetail_screen"
        static let backButton = "smartTask_taskDetail_backButton"
        static let title = "smartTask_taskDetail_title"
        static let description = "smartTask_taskDetail_description"
        static let priority = "smartTask_taskDetail_priority"
        static let dueDate = "smartTask_taskDetail_dueDate"
        static let completionStatus = "smartTask_taskDetail_completionStatus"
        static let editButton = "smartTask_taskDetail_editButton"
        static let deleteButton = "smartTask_taskDetail_deleteButton"
        static let markCompleteButton = "smartTask_taskDetail_markCompleteButton"
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
    }

    enum DeleteConfirm {
        static let alert = "smartTask_deleteConfirm_alert"
        static let deleteAction = "smartTask_deleteConfirm_delete"
        static let cancelAction = "smartTask_deleteConfirm_cancel"
    }

    enum Filter {
        static let alert = "smartTask_filter_alert"
    }

    enum TaskInputField {
        static func container(identifier: String) -> String { "smartTask_taskForm_field_\(identifier)_container" }
        static func textField(identifier: String) -> String { "smartTask_taskForm_field_\(identifier)_text" }
    }
}
