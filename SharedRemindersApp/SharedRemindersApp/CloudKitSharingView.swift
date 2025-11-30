//
//  CloudKitSharingView.swift
//  SharedRemindersApp
//
//  A SwiftUI wrapper for UICloudSharingController.
//  This displays Apple's system UI for managing CloudKit shares.
//

import SwiftUI
import CloudKit
import UIKit

/// SwiftUI wrapper for UICloudSharingController
///
/// UICloudSharingController is Apple's system UI for:
/// - Inviting people to a share
/// - Managing participants
/// - Setting permissions
/// - Generating share links
///
/// This struct bridges UIKit to SwiftUI using UIViewControllerRepresentable
struct CloudKitSharingView: UIViewControllerRepresentable {
    // MARK: - Properties

    /// The CKShare to display/manage
    let share: CKShare

    /// The CloudKit container that owns this share
    let container: CKContainer

    // MARK: - UIViewControllerRepresentable

    /// Creates the UICloudSharingController
    func makeUIViewController(context: Context) -> UICloudSharingController {
        // Create a preparationHandler for the share
        // This is called when the user wants to start sharing
        let preparationHandler: (UICloudSharingController, @escaping (CKShare?, CKContainer?, Error?) -> Void) -> Void = { controller, completion in
            // Return the share and container we already have
            completion(self.share, self.container, nil)
        }

        // Create the sharing controller
        // This is Apple's pre-built UI for managing shares
        let controller = UICloudSharingController(
            preparationHandler: preparationHandler
        )

        // Set the delegate to handle callbacks
        controller.delegate = context.coordinator

        // Configure availability - who can access this share
        // .allowPublic: Anyone with the link can access
        // .allowPrivate: Only invited people can access
        // .allowReadOnly: People can only view, not edit
        // .allowReadWrite: People can view and edit
        //
        // For a collaborative reminders app, we want private sharing with read-write access
        controller.availablePermissions = [
            .allowPrivate,
            .allowReadWrite
        ]

        print("CloudKitSharingView: Created UICloudSharingController")

        return controller
    }

    /// Updates the view controller (not needed in our case)
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }

    /// Creates the coordinator that acts as the delegate
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    /// Coordinator class that implements UICloudSharingControllerDelegate
    class Coordinator: NSObject, UICloudSharingControllerDelegate {

        /// Called when the user finishes with the sharing controller
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            // Handle save failure
            print("CloudKitSharingView: Failed to save share - \(error.localizedDescription)")

            // In a production app, you'd want to show an alert to the user
        }

        /// Called to provide an item title for the sharing UI
        func itemTitle(for csc: UICloudSharingController) -> String? {
            // This appears at the top of the sharing sheet
            return "Shared Reminder"
        }

        /// Called to provide an item thumbnail for the sharing UI (optional)
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // You could return an image here
            // For example, a screenshot of the reminder or an icon
            return nil
        }

        /// Called to provide the item type for the sharing UI
        func itemType(for csc: UICloudSharingController) -> String? {
            // This could be a UTType or custom type identifier
            return "Reminder"
        }

        /// Called when the user stops sharing
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("CloudKitSharingView: User stopped sharing")

            // The share has been deleted
            // You might want to update your UI here
        }

        /// Called when the user saves changes to the share
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("CloudKitSharingView: Share saved successfully")

            // The share has been saved with any changes
            // (e.g., new participants added, permissions changed)
        }
    }
}

// IMPORTANT: Understanding UICloudSharingController
//
// UICloudSharingController is Apple's built-in UI for sharing via CloudKit.
// It handles:
//
// 1. SHARING WORKFLOW:
//    - Shows a share sheet with options to invite people
//    - Generates a share URL that can be sent via Messages, Mail, etc.
//    - The URL contains a token that CloudKit uses to authorize access
//
// 2. PARTICIPANT MANAGEMENT:
//    - Shows who has access to the share
//    - Allows removing participants
//    - Shows pending invitations
//
// 3. PERMISSIONS:
//    - Read-only vs. read-write access
//    - Private (invited only) vs. public (anyone with link)
//
// 4. WHEN SOMEONE RECEIVES A SHARE:
//    - They tap the share link
//    - iOS asks if they want to open it in your app
//    - Your app receives the share metadata via UserActivity
//    - You call persistenceController.acceptShare(metadata:)
//    - The shared data appears in their app
//
// This is all handled automatically by iOS and CloudKit!
// You just need to:
// - Create the share (done in PersistenceController)
// - Show this controller (done in ContentView)
// - Handle incoming shares (we'll add this next)
