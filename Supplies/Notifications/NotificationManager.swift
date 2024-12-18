import Foundation
import SwiftUI
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
        await removeNotifications(for: item.id)
        
        guard !item.isOrdered else { return }
        
        @AppStorage("notificationDays") var defaultNotificationDays = 14
        
        // Use custom notification days if set, otherwise use default
        let notificationDays = item.notifyDays ?? defaultNotificationDays
        
        // Initial notification
        if item.daysUntilEmpty > notificationDays {
            let content = UNMutableNotificationContent()
            content.title = "Supply Running Low"
            content.body = "\(item.name) will be empty in \(notificationDays) days"
            content.sound = .default
            
            let notifyDate = Calendar.current.date(byAdding: .day, value: -notificationDays, to: item.estimatedEmptyDate) ?? .now
            let components = Calendar.current.dateComponents([.year, .month, .day], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(item.id)-initial",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
    
    func removeNotifications(for itemId: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["\(itemId)-initial"])
    }
} 
