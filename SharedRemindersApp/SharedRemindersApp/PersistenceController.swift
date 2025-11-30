//
//  PersistenceController.swift
//  SharedRemindersApp
//
//  This class manages the Core Data stack with CloudKit integration.
//  It handles both private data (user's own reminders) and shared data (reminders shared with others).
//

import CoreData
import CloudKit

class PersistenceController: ObservableObject {
    // MARK: - Singleton

    /// Shared instance used throughout the app
    static let shared = PersistenceController()

    // MARK: - Properties

    /// The persistent container that manages the Core Data stack
    /// NSPersistentCloudKitContainer is a special container that automatically syncs with iCloud
    let container: NSPersistentCloudKitContainer

    /// Published property to track sharing status and trigger UI updates
    @Published var canShare: Bool = false

    // MARK: - Initialization

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, uses in-memory store for testing/previews
    init(inMemory: Bool = false) {
        // Create the container with the same name as our .xcdatamodeld file
        container = NSPersistentCloudKitContainer(name: "SharedRemindersApp")

        if inMemory {
            // For previews and tests, use an in-memory store that doesn't persist
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // MARK: CloudKit Configuration

            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }

            // Enable persistent history tracking
            // This is REQUIRED for CloudKit sync - it allows Core Data to track changes
            // and sync them efficiently across devices
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            // Enable remote change notifications
            // This tells Core Data to notify us when changes arrive from CloudKit
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // CRITICAL: Configure CloudKit container options for SHARING
            let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourcompany.SharedRemindersApp")

            // The database scope determines where data is stored:
            // - .private: User's private database (default, only they can access)
            // - .public: Public database (anyone can read)
            // - .shared: Shared database (for data shared between users)
            //
            // For a sharing-enabled app, we need BOTH private and shared scopes
            // We start with .private as the default
            cloudKitOptions.databaseScope = .private

            description.cloudKitContainerOptions = cloudKitOptions
        }

        // Load the persistent stores
        // This is an asynchronous operation that connects to CloudKit
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, you'd want to handle this more gracefully
                // Possible errors: iCloud not signed in, no network, etc.
                print("Core Data store failed to load: \(error.localizedDescription)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            print("Successfully loaded persistent store: \(storeDescription)")
        }

        // MARK: View Context Configuration

        // Automatically merge changes from parent context (iCloud sync)
        // This ensures UI stays up-to-date when changes arrive from other devices
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Merge policy for conflicts
        // When two devices edit the same object, this policy determines which wins
        // .mergeByPropertyObjectTrump: Newer property values win (good for collaborative editing)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // MARK: Sharing Setup

        // Check if we can share (requires iCloud account)
        checkSharingAvailability()

        // Observe notifications for when shares change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
    }

    // MARK: - Sharing Availability

    /// Checks if CloudKit sharing is available
    /// This requires the user to be signed into iCloud
    private func checkSharingAvailability() {
        // Get the CloudKit container
        let cloudKitContainer = CKContainer(identifier: "iCloud.com.yourcompany.SharedRemindersApp")

        // Check account status
        cloudKitContainer.accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                // Only allow sharing if user is signed into iCloud
                self.canShare = (accountStatus == .available)

                if let error = error {
                    print("Error checking CloudKit account status: \(error.localizedDescription)")
                }

                if !self.canShare {
                    print("CloudKit sharing not available. User may not be signed into iCloud.")
                }
            }
        }
    }

    // MARK: - Remote Change Handling

    /// Called when changes arrive from CloudKit (other devices or other users)
    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        print("Remote changes detected from CloudKit")

        // The view context will automatically merge these changes due to
        // automaticallyMergesChangesFromParent = true
        // This method is here so you can add custom logic if needed
        // (e.g., show a notification to the user, refresh specific UI, etc.)
    }

    // MARK: - Sharing Functions

    /// Creates a CloudKit share for a reminder item
    /// This generates a share URL that can be sent to other users
    ///
    /// - Parameter reminder: The ReminderItem to share
    /// - Returns: A tuple containing the CKShare and CKContainer
    /// - Throws: Error if sharing fails
    func createShare(for reminder: ReminderItem) async throws -> (CKShare, CKContainer) {
        print("Creating share for reminder: \(reminder.title ?? "Unknown")")

        // Get the managed object context
        let context = container.viewContext

        // IMPORTANT: The share(for:to:) method is KEY to CloudKit sharing
        // It creates a CKShare record and associates it with the Core Data object
        // The persistentStore parameter determines which CloudKit database to use
        guard let persistentStore = context.persistentStoreCoordinator?.persistentStores.first else {
            throw NSError(domain: "PersistenceController", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No persistent store found"
            ])
        }

        // Create the share
        // This method:
        // 1. Creates a CKShare record in CloudKit
        // 2. Links it to the Core Data object
        // 3. Moves the object to the shared database
        let (_, share, container) = try await container.share([reminder], to: persistentStore)

        // Configure share permissions
        share[CKShare.SystemFieldKey.title] = "Shared Reminder: \(reminder.title ?? "")"
        share.publicPermission = .none // Only invited users can access

        // Save the share configuration
        try context.save()

        print("Successfully created share")
        return (share, container)
    }

    /// Checks if a reminder is already shared
    ///
    /// - Parameter reminder: The ReminderItem to check
    /// - Returns: The associated CKShare if it exists, nil otherwise
    func getShare(for reminder: ReminderItem) -> CKShare? {
        let context = container.viewContext

        // Check if this object has an associated share
        guard let shareSet = try? container.fetchShares(matching: [reminder.objectID]) else {
            return nil
        }

        // Return the share if found
        if let share = shareSet[reminder.objectID] {
            return share
        }

        return nil
    }

    /// Deletes a share (stops sharing a reminder)
    ///
    /// - Parameter share: The CKShare to delete
    func deleteShare(_ share: CKShare) async throws {
        print("Deleting share")

        let context = container.viewContext

        // Delete the share
        // This removes the share record from CloudKit and revokes access for all participants
        try await container.delete(share)

        // Save the context
        try context.save()

        print("Successfully deleted share")
    }

    /// Accepts a CloudKit share invitation
    /// This is called when a user taps a share link
    ///
    /// - Parameter metadata: The share metadata from the invitation
    func acceptShare(metadata: CKShare.Metadata) async throws {
        print("Accepting share invitation")

        // Accept the share
        // This adds the shared data to the user's shared database
        try await container.acceptShareInvitations(from: [metadata])

        print("Successfully accepted share")
    }

    // MARK: - Helper Functions

    /// Saves the view context if there are changes
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully")
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }

    /// Creates a new reminder item
    ///
    /// - Parameters:
    ///   - title: The reminder title
    ///   - isCompleted: Whether the reminder is completed (default: false)
    /// - Returns: The newly created ReminderItem
    func createReminder(title: String, isCompleted: Bool = false) -> ReminderItem {
        let context = container.viewContext

        let reminder = ReminderItem(context: context)
        reminder.id = UUID()
        reminder.title = title
        reminder.isCompleted = isCompleted
        reminder.createdAt = Date()
        reminder.modifiedAt = Date()

        save()

        print("Created new reminder: \(title)")
        return reminder
    }

    /// Deletes a reminder item
    ///
    /// - Parameter reminder: The ReminderItem to delete
    func deleteReminder(_ reminder: ReminderItem) {
        let context = container.viewContext

        // If this reminder is shared, we should also delete the share
        if let share = getShare(for: reminder) {
            Task {
                try? await deleteShare(share)
            }
        }

        context.delete(reminder)
        save()

        print("Deleted reminder: \(reminder.title ?? "Unknown")")
    }

    /// Toggles the completion status of a reminder
    ///
    /// - Parameter reminder: The ReminderItem to toggle
    func toggleCompletion(for reminder: ReminderItem) {
        reminder.isCompleted.toggle()
        reminder.modifiedAt = Date()
        save()

        print("Toggled reminder completion: \(reminder.title ?? "Unknown") - \(reminder.isCompleted ? "Completed" : "Not completed")")
    }
}

// MARK: - Preview Helper

extension PersistenceController {
    /// Creates a preview instance with sample data for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Create sample data
        let context = controller.container.viewContext

        let reminder1 = ReminderItem(context: context)
        reminder1.id = UUID()
        reminder1.title = "Buy groceries"
        reminder1.isCompleted = false
        reminder1.createdAt = Date()
        reminder1.modifiedAt = Date()

        let reminder2 = ReminderItem(context: context)
        reminder2.id = UUID()
        reminder2.title = "Walk the dog"
        reminder2.isCompleted = true
        reminder2.createdAt = Date().addingTimeInterval(-3600)
        reminder2.modifiedAt = Date().addingTimeInterval(-3600)

        let reminder3 = ReminderItem(context: context)
        reminder3.id = UUID()
        reminder3.title = "Finish homework"
        reminder3.isCompleted = false
        reminder3.createdAt = Date().addingTimeInterval(-7200)
        reminder3.modifiedAt = Date().addingTimeInterval(-7200)

        do {
            try context.save()
        } catch {
            print("Error creating preview data: \(error.localizedDescription)")
        }

        return controller
    }()
}
