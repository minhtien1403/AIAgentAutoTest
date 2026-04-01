import Foundation

enum CreateTaskMode: Sendable {
    case create
    case edit(Task)
}

@MainActor
final class CreateTaskViewModel {
    private let repository: TaskRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    let mode: CreateTaskMode

    var titleText: String = ""
    var descriptionText: String = ""
    var priority: Priority = .medium
    var taskStatus: TaskStatus = .todo
    var dueDate: Date?
    var hasDueDate: Bool = false
    var categoryId: UUID?

    private(set) var categories: [Category] = []

    init(repository: TaskRepositoryProtocol, categoryRepository: CategoryRepositoryProtocol, mode: CreateTaskMode) {
        self.repository = repository
        self.categoryRepository = categoryRepository
        self.mode = mode
        switch mode {
        case .create:
            break
        case .edit(let task):
            titleText = task.title
            descriptionText = task.description ?? ""
            priority = task.priority
            taskStatus = task.taskStatus
            dueDate = task.dueDate
            hasDueDate = task.dueDate != nil
            categoryId = task.categoryId
        }
    }

    func loadCategories() {
        do {
            categories = try categoryRepository.fetchCategories()
        } catch {
            categories = []
        }
    }

    var isTitleValid: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() throws {
        guard isTitleValid else { throw CreateTaskError.titleRequired }
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let desc = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .create:
            let task = Task(
                title: trimmedTitle,
                description: desc.isEmpty ? nil : desc,
                priority: priority,
                taskStatus: taskStatus,
                dueDate: hasDueDate ? dueDate : nil,
                categoryId: categoryId
            )
            try repository.save(task)
        case .edit(let existing):
            var updated = existing
            updated.title = trimmedTitle
            updated.description = desc.isEmpty ? nil : desc
            updated.priority = priority
            updated.applyTaskStatus(taskStatus)
            updated.dueDate = hasDueDate ? dueDate : nil
            updated.categoryId = categoryId
            try repository.save(updated)
        }
    }
}

enum CreateTaskError: Error {
    case titleRequired
}
