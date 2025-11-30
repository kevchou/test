//
//  SharedRemindersAppApp.swift
//  SharedRemindersApp
//
//  Main entry point for the Shared Reminders app.
//  This app demonstrates Core Data + CloudKit sharing for collaborative task management.
//

import SwiftUI

@main
struct SharedRemindersAppApp: App {
    // MARK: - Properties

    /// The persistence controller manages our Core Data stack with CloudKit integration.
    /// We use @StateObject to ensure it's created once and persists for the app's lifetime.
    @StateObject private var persistenceController = PersistenceController.shared

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the managed object context into the SwiftUI environment.
                // This allows any view in the hierarchy to access Core Data.
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Handle incoming CloudKit share URLs
                // This is called when someone taps a share link
                .onOpenURL { url in
                    print("Received URL: \(url)")
                    // Create a user activity for the URL
                    let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                    userActivity.webpageURL = url
                    handleIncomingShare(userActivity)
                }
        }
    }
}
