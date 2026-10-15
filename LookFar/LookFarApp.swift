import SwiftUI
import UserNotifications

@main
struct LookFarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var store = ReminderStore()
    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .tint(Palette.coral)
                .preferredColorScheme(.dark)
                .onAppear { delegate.store = store }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var store: ReminderStore?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([
            UNNotificationCategory(identifier: "LOOKFAR", actions: [
                UNNotificationAction(identifier: "REST", title: L("눈 쉬기", "Take a break"), options: .foreground),
                UNNotificationAction(identifier: "SNOOZE", title: L("5분 뒤 알림", "Remind in 5 min"), options: .foreground)
            ], intentIdentifiers: [])
        ])
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            // Store the route as well: notification taps can arrive before SwiftUI attaches the store.
            let action = response.actionIdentifier == "SNOOZE" ? "snooze" : "rest"
            UserDefaults.standard.set(action, forKey: "notificationRoute")
            await store?.handleNotificationRoute()
            completionHandler()
        }
    }
}
