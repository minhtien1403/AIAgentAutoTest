import Foundation

enum CreateTaskMode: Sendable {
    case create
    case edit(Task)
}

@MainActor
final class CreateTaskViewModel {
    private let repository: TaskRepositoryProtocol
    let mode: CreateTaskMode

    var titleText: String = ""
    var descriptionText: String = ""
    var priority: Priority = .medium
    var dueDate: Date?
    var hasDueDate: Bool = false

    init(repository: TaskRepositoryProtocol, mode: CreateTaskMode) {
        self.repository = repository
        self.mode = mode
        switch mode {
        case .create:
            break
        case .edit(let task):
            titleText = task.title
            descriptionText = task.description ?? ""
            priority = task.priority
            dueDate = task.dueDate
            hasDueDate = task.dueDate != nil
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
                dueDate: hasDueDate ? dueDate : nil
            )
            try repository.save(task)
        case .edit(let existing):
            var updated = existing
            updated.title = trimmedTitle
            updated.description = desc.isEmpty ? nil : desc
            updated.priority = priority
            updated.dueDate = hasDueDate ? dueDate : nil
            try repository.save(updated)
        }
    }
}

enum CreateTaskError: Error {
    case titleRequired
}
