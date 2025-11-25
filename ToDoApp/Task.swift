import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

struct Task: Identifiable, Codable, Equatable {
    let id: String          // Firestore document ID (string)
    var title: String
    var details: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var priority: TaskPriority
    var reminderDate: Date?

    init(
        id: String = UUID().uuidString,
        title: String,
        details: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        reminderDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.priority = priority
        self.reminderDate = reminderDate
    }
}
