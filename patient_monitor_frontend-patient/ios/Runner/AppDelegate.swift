import UIKit
import Flutter
import AVFoundation
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    // MARK: - Application Lifecycle
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Initialize Flutter plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure app-wide settings
        configureAppSettings()
        
        // Configure audio session for video calls
        configureAudioSession()
        
        // Setup notifications
        setupNotifications(application: application)
        
        // Configure appearance
        configureAppearance()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Configuration Methods
    
    private func configureAppSettings() {
        // Enable battery monitoring for health tracking
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Set minimum background fetch interval
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for video calls with optimal settings
            try audioSession.setCategory(
                .playAndRecord,
                mode: .videoChat,
                options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .mixWithOthers]
            )
            
            // Set preferred sample rate and I/O buffer duration for better audio quality
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            // Activate the audio session
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("✅ Audio session configured successfully")
            
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupNotifications(application: UIApplication) {
        // Request notification permissions
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
        center.requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("✅ Notification permissions granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ Notification permissions denied")
            }
        }
        
        // Set notification categories for actionable notifications
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        // Health alert category
        let healthAlertCategory = UNNotificationCategory(
            identifier: "HEALTH_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_DETAILS",
                    title: "View Details",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "CONTACT_DOCTOR",
                    title: "Contact Doctor",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // Emergency category
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY",
            actions: [
                UNNotificationAction(
                    identifier: "CALL_EMERGENCY",
                    title: "Call Emergency",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SEND_ALERT",
                    title: "Send Alert",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            healthAlertCategory,
            emergencyCategory
        ])
    }
    
    private func configureAppearance() {
        if #available(iOS 13.0, *) {
            // Configure navigation bar appearance for iOS 13+
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor.systemBackground
            navigationBarAppearance.shadowColor = .clear
            
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            
            // Configure tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    // MARK: - Background Tasks
    
    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Perform background health data synchronization
        print("🔄 Performing background fetch for health data")
        
        // Simulate health data sync
        DispatchQueue.global(qos: .background).async {
            // In a real app, this would sync with health devices/APIs
            sleep(2) // Simulate work
            
            // Notify Flutter about background update if needed
            if let controller = window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "com.example.patientMonitor/background",
                    binaryMessenger: controller.binaryMessenger
                )
                
                channel.invokeMethod("onBackgroundFetch", arguments: nil)
            }
            
            completionHandler(.newData)
        }
    }
    
    // MARK: - Remote Notifications
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        
        // Send token to your server or Flutter side
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.patientMonitor/notifications",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onTokenReceived", arguments: token)
        }
    }
    
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Notification Handling
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification when app is in foreground
        let userInfo = notification.request.content.userInfo
        
        print("📲 Received notification in foreground: \(userInfo)")
        
        // Show alert and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        // Notify Flutter about the notification
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.patientMonitor/notifications",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onNotificationReceived", arguments: userInfo)
        }
    }
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        print("👆 Notification action triggered: \(actionIdentifier)")
        
        // Handle notification actions
        handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case "VIEW_DETAILS":
            print("📍 Handling VIEW_DETAILS action")
            // Navigate to health details in Flutter
            notifyFlutter(action: "navigateToHealthDetails", data: userInfo)
            
        case "CONTACT_DOCTOR":
            print("📞 Handling CONTACT_DOCTOR action")
            // Open chat with doctor in Flutter
            notifyFlutter(action: "openDoctorChat", data: userInfo)
            
        case "CALL_EMERGENCY":
            print("🚨 Handling CALL_EMERGENCY action")
            // Initiate emergency call
            if let url = URL(string: "tel://911") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case "SEND_ALERT":
            print("⚠️ Handling SEND_ALERT action")
            // Send emergency alert
            notifyFlutter(action: "sendEmergencyAlert", data: userInfo)
            
        case UNNotificationDefaultActionIdentifier:
            print("👆 Notification tapped")
            // Default tap action - open relevant screen
            notifyFlutter(action: "onNotificationTap", data: userInfo)
            
        default:
            break
        }
    }
    
    private func notifyFlutter(action: String, data: [AnyHashable: Any]) {
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.patientMonitor/notifications",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod(action, arguments: data)
        }
    }
    
    // MARK: - URL Handling
    
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("🔗 Handling URL: \(url.absoluteString)")
        
        // Handle custom URL schemes for deep linking
        if url.scheme == "patientmonitor" {
            handleDeepLink(url: url)
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
    
    private func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        
        let path = components.path
        let queryItems = components.queryItems
        
        print("🔗 Deep link path: \(path)")
        
        // Notify Flutter about the deep link
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.patientMonitor/deeplink",
                binaryMessenger: controller.binaryMessenger
            )
            
            var parameters: [String: Any] = ["path": path]
            if let queryItems = queryItems {
                for item in queryItems {
                    parameters[item.name] = item.value
                }
            }
            
            channel.invokeMethod("onDeepLink", arguments: parameters)
        }
    }
    
    // MARK: - Memory Warning
    
    override func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("⚠️ Memory warning received")
        // Clear caches or perform memory cleanup
    }
    
    // MARK: - Background Audio Support
    
    override func applicationWillResignActive(_ application: UIApplication) {
        print("📱 App will resign active")
        // Pause ongoing tasks, timers, etc.
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 App entered background")
        
        // Request additional background time if needed for critical operations
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        
        backgroundTask = application.beginBackgroundTask {
            print("⏰ Background time expired")
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Perform final health data sync before going to background
        DispatchQueue.global(qos: .background).async {
            // Sync critical health data
            sleep(5) // Simulate sync work
            
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 App will enter foreground")
        // Refresh data, check for updates
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 App became active")
        
        // Clear app badge
        application.applicationIconBadgeNumber = 0
        
        // Refresh health data
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.patientMonitor/applifecycle",
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onAppResumed", arguments: nil)
        }
    }
    
    // MARK: - Orientation Support
    
    override func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Allow all orientations for flexibility in different app sections
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
}