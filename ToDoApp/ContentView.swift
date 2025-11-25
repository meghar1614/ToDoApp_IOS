import SwiftUI

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"

    var id: String { rawValue }
}

enum TaskSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case titleAZ = "Title A–Z"
    case titleZA = "Title Z–A"

    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject var taskStore: TaskStore

    @State private var showAddSheet = false
    @State private var taskBeingEdited: Task?

    @State private var filter: TaskFilter = .all
    @State private var sort: TaskSort = .newest

    private var displayedTasks: [Task] {
        let filtered: [Task] = {
            switch filter {
            case .all:
                return taskStore.tasks
            case .active:
                return taskStore.tasks.filter { !$0.isCompleted }
            case .completed:
                return taskStore.tasks.filter { $0.isCompleted }
            }
        }()

        return filtered.sorted { lhs, rhs in
            switch sort {
            case .newest:
                return lhs.createdAt > rhs.createdAt
            case .oldest:
                return lhs.createdAt < rhs.createdAt
            case .titleAZ:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .titleZA:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedDescending
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Filter + sort controls
                HStack {
                    Picker("Filter", selection: $filter) {
                        ForEach(TaskFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)

                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(TaskSort.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
                .padding(.horizontal)

                Group {
                    if displayedTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.largeTitle)
                            Text("No tasks")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Add a task to get started.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(displayedTasks) { task in
                                Button {
                                    taskBeingEdited = task
                                } label: {
                                    TaskRowView(task: task) {
                                        withAnimation {
                                            taskStore.toggleCompletion(for: task)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            taskStore.delete(task: task)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("My To-Do List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTaskView { title, details, priority, due, reminder in
                taskStore.addTask(
                    title: title,
                    details: details,
                    priority: priority,
                    dueDate: due,
                    reminderDate: reminder
                )
            }
        }
        .sheet(item: $taskBeingEdited) { task in
            EditTaskView(task: task) { newTitle, newDetails, newPriority, newDue, newReminder in
                taskStore.update(
                    task: task,
                    newTitle: newTitle,
                    newDetails: newDetails,
                    newPriority: newPriority,
                    newDueDate: newDue,
                    newReminderDate: newReminder
                )
            }
        }
    }
}
