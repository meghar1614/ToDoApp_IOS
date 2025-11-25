import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Notification auth error:", error.localizedDescription)
            } else {
                print("Notifications granted:", granted)
            }
        }
    }

    func scheduleReminder(for task: Task) {
        guard let date = task.reminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: task.id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Schedule reminder error:", error.localizedDescription)
            }
        }
    }

    func cancelReminder(for task: Task) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id])
    }
}
