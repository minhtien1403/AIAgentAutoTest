import Foundation

struct Category: Equatable, Sendable, Identifiable {
    let id: UUID
    var name: String
    var color: String

    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}
