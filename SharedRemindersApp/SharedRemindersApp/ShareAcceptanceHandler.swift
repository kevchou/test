//
//  ShareAcceptanceHandler.swift
//  SharedRemindersApp
//
//  Handles incoming CloudKit share invitations.
//  When someone taps a share link, this code accepts the share and adds the data to the app.
//

import SwiftUI
import CloudKit

extension SharedRemindersAppApp {
    /// Handle incoming CloudKit share when user taps a share link
    ///
    /// This is called by iOS when:
    /// 1. User taps a share link (e.g., from Messages or Mail)
    /// 2. iOS recognizes it's a CloudKit share for your app
    /// 3. iOS asks your app to handle it via NSUserActivity
    ///
    /// To enable this, you need to add the CKSharingSupported key to Info.plist
    func handleIncomingShare(_ userActivity: NSUserActivity) {
        print("ShareAcceptanceHandler: Received incoming share activity")

        // Check if this is a CloudKit sharing activity
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            print("ShareAcceptanceHandler: Not a web browsing activity")
            return
        }

        // Get the URL from the activity
        guard let incomingURL = userActivity.webpageURL else {
            print("ShareAcceptanceHandler: No URL in activity")
            return
        }

        print("ShareAcceptanceHandler: Processing URL: \(incomingURL)")

        // Get share metadata from the URL
        // This extracts the CloudKit share information embedded in the URL
        let container = CKContainer(identifier: "iCloud.com.yourcompany.SharedRemindersApp")

        Task {
            do {
                // Fetch the share metadata
                let metadata = try await container.shareMetadata(for: incomingURL)

                print("ShareAcceptanceHandler: Fetched share metadata")
                print("  - Share title: \(metadata.share.title ?? "No title")")
                print("  - Owner: \(metadata.ownerIdentity.nameComponents?.formatted() ?? "Unknown")")

                // Accept the share
                // This adds the shared data to the user's shared database
                try await persistenceController.acceptShare(metadata: metadata)

                print("ShareAcceptanceHandler: Successfully accepted share!")

                // The shared reminder will now automatically appear in the app
                // thanks to Core Data + CloudKit sync

                // Optionally, show a success message to the user
                await MainActor.run {
                    // You could show an alert here:
                    // "Successfully added shared reminder from [owner name]!"
                }

            } catch {
                print("ShareAcceptanceHandler: Failed to accept share - \(error.localizedDescription)")

                // Show error to user
                await MainActor.run {
                    // You could show an alert here:
                    // "Failed to accept share: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - How CloudKit Sharing Works (Educational Comments)
//
// Here's the complete flow of sharing and accepting shares:
//
// === SHARING FLOW (Person A shares with Person B) ===
//
// 1. Person A creates a reminder in their app
//    - Stored in their private CloudKit database
//    - Only they can see it
//
// 2. Person A taps the share button
//    - App calls persistenceController.createShare(for: reminder)
//    - This creates a CKShare record in CloudKit
//    - The reminder is moved to Person A's "shared zone"
//    - A share URL is generated: https://www.icloud.com/...
//
// 3. Person A sends the URL to Person B
//    - Via Messages, Mail, AirDrop, etc.
//    - The URL contains an encrypted token with share info
//
// === ACCEPTING FLOW (Person B receives the share) ===
//
// 4. Person B taps the URL
//    - iOS recognizes it's a CloudKit share URL
//    - iOS checks which app can handle it (based on container ID)
//    - iOS opens the app and passes the URL via NSUserActivity
//
// 5. App receives the NSUserActivity
//    - handleIncomingShare() is called
//    - We extract share metadata from the URL
//
// 6. App accepts the share
//    - persistenceController.acceptShare(metadata:)
//    - CloudKit adds Person B as a participant
//    - The reminder appears in Person B's "shared database"
//
// 7. Core Data syncs automatically
//    - NSPersistentCloudKitContainer monitors the shared database
//    - Changes sync bidirectionally between A and B
//    - When either person edits, the other sees it immediately
//
// === SYNCING FLOW (After sharing is established) ===
//
// 8. Person B edits the reminder
//    - Core Data saves to local database
//    - NSPersistentCloudKitContainer syncs to CloudKit
//    - CloudKit updates the shared zone
//
// 9. Person A's device receives the change
//    - NSPersistentCloudKitContainer detects remote change
//    - Downloads the updated data
//    - Merges into local database
//    - UI automatically updates (thanks to @FetchRequest)
//
// This all happens automatically! You just need to:
// - Set up NSPersistentCloudKitContainer properly ✓
// - Create shares via UICloudSharingController ✓
// - Accept shares when URLs are opened ✓
// - Core Data + CloudKit handle the rest!
