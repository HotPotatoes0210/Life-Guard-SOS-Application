import UserNotifications
import SwiftData
import Combine
import CoreLocation
import UIKit

// Request notification permission
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Notification permission granted")
        } else if let error = error {
            print("Error: \(error.localizedDescription)")
        } else {
            print("Notification permission denied")
        }
    }
}

// Register and send a notification
func registerNotification(message_incoming: String) {
    let content = UNMutableNotificationContent()
    content.title = "LifeGuard Alert"
    content.body = message_incoming
    content.sound = UNNotificationSound.default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    
    let request = UNNotificationRequest(identifier: "FireNotification", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling notification: \(error.localizedDescription)")
        } else {
            print("Notification scheduled successfully")
        }
    }
}

// Handle notifications in foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) 
    }
}
