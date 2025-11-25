import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var hasReminder: Bool
    @State private var reminderDate: Date

    let onSave: (String, String, TaskPriority, Date?, Date?) -> Void

    init(task: Task, onSave: @escaping (String, String, TaskPriority, Date?, Date?) -> Void) {
        _title = State(initialValue: task.title)
        _details = State(initialValue: task.details)
        _priority = State(initialValue: task.priority)

        if let due = task.dueDate {
            _hasDueDate = State(initialValue: true)
            _dueDate = State(initialValue: due)
        } else {
            _hasDueDate = State(initialValue: false)
            _dueDate = State(initialValue: Date())
        }

        if let remind = task.reminderDate {
            _hasReminder = State(initialValue: true)
            _reminderDate = State(initialValue: remind)
        } else {
            _hasReminder = State(initialValue: false)
            _reminderDate = State(
                initialValue: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
                ?? Date()
            )
        }

        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $details, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }

                Section("Reminder") {
                    Toggle("Set reminder", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker(
                            "Remind me at",
                            selection: $reminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let due = hasDueDate ? dueDate : nil
                        let reminder = hasReminder ? reminderDate : nil
                        onSave(title, details, priority, due, reminder)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
