import Foundation
import Combine
import FirebaseFirestore

final class TaskStore: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet { saveLocalCache() }
    }

    private let db = Firestore.firestore()
    private let collectionPath = "tasks"
    private var listener: ListenerRegistration?
    private let cacheKey = "todo_tasks_cache_v1"

    init() {
        loadLocalCache()
        NotificationManager.shared.requestAuthorization()
        startListeningToFirestore()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Firestore listener

    private func startListeningToFirestore() {
        listener?.remove()
        listener = db.collection(collectionPath)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Firestore listener error:", error.localizedDescription)
                    return
                }
                guard let docs = snapshot?.documents else { return }

                let remoteTasks: [Task] = docs.compactMap { doc in
                    let data = doc.data()

                    let title = data["title"] as? String ?? ""
                    let details = data["details"] as? String ?? ""
                    let isCompleted = data["isCompleted"] as? Bool ?? false

                    var createdAt = Date()
                    if let ts = data["createdAt"] as? Timestamp {
                        createdAt = ts.dateValue()
                    }

                    var dueDate: Date? = nil
                    if let ts = data["dueDate"] as? Timestamp {
                        dueDate = ts.dateValue()
                    }

                    var reminderDate: Date? = nil
                    if let ts = data["reminderDate"] as? Timestamp {
                        reminderDate = ts.dateValue()
                    }

                    let priorityRaw = data["priority"] as? String ?? TaskPriority.medium.rawValue
                    let priority = TaskPriority(rawValue: priorityRaw) ?? .medium

                    return Task(
                        id: doc.documentID,
                        title: title,
                        details: details,
                        isCompleted: isCompleted,
                        createdAt: createdAt,
                        dueDate: dueDate,
                        priority: priority,
                        reminderDate: reminderDate
                    )
                }

                DispatchQueue.main.async {
                    self.tasks = remoteTasks
                }
            }
    }

    // MARK: - CRUD (write to Firestore)

    func addTask(title: String,
                 details: String,
                 priority: TaskPriority,
                 dueDate: Date?,
                 reminderDate: Date?) {

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newTask = Task(
            title: trimmedTitle,
            details: details,
            isCompleted: false,
            createdAt: Date(),
            dueDate: dueDate,
            priority: priority,
            reminderDate: reminderDate
        )

        var dict: [String: Any] = [
            "title": newTask.title,
            "details": newTask.details,
            "isCompleted": newTask.isCompleted,
            "createdAt": newTask.createdAt,
            "priority": newTask.priority.rawValue
        ]
        if let due = newTask.dueDate {
            dict["dueDate"] = due
        }
        if let remind = newTask.reminderDate {
            dict["reminderDate"] = remind
        }

        print("🔥 Trying to add task to Firestore…")
        db.collection(collectionPath).addDocument(data: dict) { error in
            if let error = error {
                print("❌ Firestore addDocument error:", error.localizedDescription)
            } else {
                print("✅ Firestore addDocument success")
            }
        }

        if reminderDate != nil {
            NotificationManager.shared.scheduleReminder(for: newTask)
        }
    }


    func toggleCompletion(for task: Task) {
        db.collection(collectionPath)
            .document(task.id)
            .updateData(["isCompleted": !task.isCompleted]) { error in
                if let error = error {
                    print("Toggle error:", error.localizedDescription)
                }
            }
    }

    func update(task: Task,
                newTitle: String,
                newDetails: String,
                newPriority: TaskPriority,
                newDueDate: Date?,
                newReminderDate: Date?) {

        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        var dict: [String: Any] = [
            "title": trimmedTitle,
            "details": newDetails,
            "priority": newPriority.rawValue
        ]
        if let due = newDueDate {
            dict["dueDate"] = due
        } else {
            dict["dueDate"] = FieldValue.delete()
        }
        if let remind = newReminderDate {
            dict["reminderDate"] = remind
        } else {
            dict["reminderDate"] = FieldValue.delete()
        }

        db.collection(collectionPath)
            .document(task.id)
            .setData(dict, merge: true) { error in
                if let error = error {
                    print("Update error:", error.localizedDescription)
                }
            }

        // reschedule local reminder
        NotificationManager.shared.cancelReminder(for: task)
        let updatedTask = Task(
            id: task.id,
            title: trimmedTitle,
            details: newDetails,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            dueDate: newDueDate,
            priority: newPriority,
            reminderDate: newReminderDate
        )
        if newReminderDate != nil {
            NotificationManager.shared.scheduleReminder(for: updatedTask)
        }
    }

    func delete(task: Task) {
        NotificationManager.shared.cancelReminder(for: task)
        db.collection(collectionPath)
            .document(task.id)
            .delete { error in
                if let error = error {
                    print("Delete error:", error.localizedDescription)
                }
            }
    }

    // MARK: - Local cache (UserDefaults)

    private func saveLocalCache() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("Save cache error:", error)
        }
    }

    private func loadLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        do {
            let cached = try JSONDecoder().decode([Task].self, from: data)
            if !cached.isEmpty {
                tasks = cached
            }
        } catch {
            print("Load cache error:", error)
        }
    }
}
