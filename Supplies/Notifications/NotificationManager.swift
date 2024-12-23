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
        let notificationDays = item.notifyDays ?? defaultNotificationDays
        
        // Only schedule if days until empty is less than or equal to notification days
        if item.daysUntilEmpty <= notificationDays {
            let content = UNMutableNotificationContent()
            content.title = "Supply Running Low"
            content.body = "\(item.name) will be empty in \(item.daysUntilEmpty) days"
            content.sound = .default
            
            // Schedule notification for now since we're already in the notification window
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
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
