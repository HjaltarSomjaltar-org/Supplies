import Foundation
import UserNotifications

@globalActor
actor NotificationManagerActor {
    static let shared = NotificationManagerActor()
}

@NotificationManagerActor
final class NotificationManager: @unchecked Sendable {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    func scheduleNotifications(for item: ItemDTO) async {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications first
        await removeNotifications(for: item.id)
        
        // Only schedule if not ordered
        guard !item.isOrdered else { return }
        
        // Two weeks notification
        if item.daysUntilEmpty > 14 {
            let content = UNMutableNotificationContent()
            content.title = "Supply Running Low"
            content.body = "\(item.name) will be empty in two weeks"
            content.sound = .default
            
            let twoWeeksDate = Calendar.current.date(byAdding: .day, value: -14, to: item.estimatedEmptyDate) ?? .now
            let components = Calendar.current.dateComponents([.year, .month, .day], from: twoWeeksDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(item.id)-14days",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
        
        // One week notification
        if item.daysUntilEmpty > 7 {
            let content = UNMutableNotificationContent()
            content.title = "Supply Almost Empty"
            content.body = "\(item.name) will be empty in one week"
            content.sound = .default
            
            let oneWeekDate = Calendar.current.date(byAdding: .day, value: -7, to: item.estimatedEmptyDate) ?? .now
            let components = Calendar.current.dateComponents([.year, .month, .day], from: oneWeekDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(item.id)-7days",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
        
        // Daily notifications starting from 7 days before
        if item.daysUntilEmpty > 0 {
            let content = UNMutableNotificationContent()
            content.title = "Order Required"
            content.body = "\(item.name) needs to be ordered"
            content.sound = .default
            
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: item.estimatedEmptyDate) ?? .now
            if startDate > .now {
                let components = DateComponents(hour: 10) // Notification at 10 AM
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                let request = UNNotificationRequest(
                    identifier: "\(item.id)-daily",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }
    
    func removeNotifications(for itemId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = [
            "\(itemId)-14days",
            "\(itemId)-7days",
            "\(itemId)-daily"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
} 