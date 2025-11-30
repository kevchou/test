# CloudKit Sharing Patterns - Quick Reference

This guide provides common patterns and code snippets for implementing CloudKit sharing in your own apps.

## Table of Contents
1. [Basic Setup](#basic-setup)
2. [Creating Shares](#creating-shares)
3. [Managing Shares](#managing-shares)
4. [Accepting Shares](#accepting-shares)
5. [Handling Permissions](#handling-permissions)
6. [Common Patterns](#common-patterns)

---

## Basic Setup

### 1. NSPersistentCloudKitContainer Configuration

```swift
let container = NSPersistentCloudKitContainer(name: "YourModelName")

guard let description = container.persistentStoreDescriptions.first else {
    fatalError("No store description")
}

// REQUIRED: Enable persistent history tracking
description.setOption(true as NSNumber,
    forKey: NSPersistentHistoryTrackingKey)

// REQUIRED: Enable remote change notifications
description.setOption(true as NSNumber,
    forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// REQUIRED: Configure CloudKit container
let cloudKitOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.yourcompany.YourApp"
)
cloudKitOptions.databaseScope = .private
description.cloudKitContainerOptions = cloudKitOptions

// Configure view context
container.viewContext.automaticallyMergesChangesFromParent = true
container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```

### 2. Required Capabilities in Xcode

1. **iCloud Capability:**
   - Enable CloudKit
   - Add container: `iCloud.com.yourcompany.YourApp`

2. **Background Modes:**
   - Enable "Remote notifications"

3. **Info.plist:**
   ```xml
   <key>CKSharingSupported</key>
   <true/>
   ```

---

## Creating Shares

### Pattern 1: Basic Share Creation

```swift
func shareObject(_ object: NSManagedObject) async throws -> (CKShare, CKContainer) {
    let context = container.viewContext

    guard let store = context.persistentStoreCoordinator?.persistentStores.first else {
        throw ShareError.noStore
    }

    // Create the share
    let (_, share, container) = try await container.share([object], to: store)

    // Configure share metadata
    share[CKShare.SystemFieldKey.title] = "Shared Item"
    share.publicPermission = .none  // Private sharing only

    // Save
    try context.save()

    return (share, container)
}
```

### Pattern 2: Share with Custom Metadata

```swift
func shareWithMetadata(_ object: NSManagedObject, title: String, thumbnail: UIImage?) async throws -> CKShare {
    let (_, share, _) = try await container.share([object], to: store)

    // Set title
    share[CKShare.SystemFieldKey.title] = title

    // Set thumbnail
    if let thumbnail = thumbnail,
       let imageData = thumbnail.jpegData(compressionQuality: 0.7) {
        let asset = CKAsset(data: imageData)
        share[CKShare.SystemFieldKey.thumbnailImageData] = asset
    }

    // Set permissions
    share.publicPermission = .none  // .readOnly or .readWrite for public shares

    try context.save()
    return share
}
```

### Pattern 3: Share Multiple Related Objects

```swift
func shareObjectHierarchy(parent: NSManagedObject, children: [NSManagedObject]) async throws -> CKShare {
    // Include parent and all children in the share
    let allObjects = [parent] + children

    let (_, share, _) = try await container.share(allObjects, to: store)

    share[CKShare.SystemFieldKey.title] = "Shared Collection"
    try context.save()

    return share
}
```

---

## Managing Shares

### Pattern 1: Check if Object is Shared

```swift
func isShared(_ object: NSManagedObject) -> Bool {
    if let share = try? container.fetchShares(matching: [object.objectID]),
       share[object.objectID] != nil {
        return true
    }
    return false
}
```

### Pattern 2: Get Existing Share

```swift
func getShare(for object: NSManagedObject) -> CKShare? {
    guard let shares = try? container.fetchShares(matching: [object.objectID]) else {
        return nil
    }
    return shares[object.objectID]
}
```

### Pattern 3: Delete/Stop Sharing

```swift
func stopSharing(_ share: CKShare) async throws {
    // Delete the share - this revokes access for all participants
    try await container.delete(share)

    // Object moves back to private database
    try container.viewContext.save()
}
```

### Pattern 4: Update Share Permissions

```swift
func updateSharePermissions(_ share: CKShare, allowPublic: Bool) async throws {
    // Update permissions
    share.publicPermission = allowPublic ? .readWrite : .none

    // Save changes
    // Note: You need to save the share to CloudKit
    let database = CKContainer(identifier: "iCloud.com.yourcompany.YourApp").privateCloudDatabase

    try await database.save(share)
}
```

---

## Accepting Shares

### Pattern 1: Handle Incoming Share URL

```swift
// In your App struct or SceneDelegate
.onOpenURL { url in
    handleIncomingShare(url)
}

func handleIncomingShare(_ url: URL) {
    let container = CKContainer(identifier: "iCloud.com.yourcompany.YourApp")

    Task {
        do {
            // Get share metadata from URL
            let metadata = try await container.shareMetadata(for: url)

            // Accept the share
            try await acceptShare(metadata: metadata)
        } catch {
            print("Failed to accept share: \(error)")
        }
    }
}
```

### Pattern 2: Accept Share with Metadata

```swift
func acceptShare(metadata: CKShare.Metadata) async throws {
    // Accept the share invitation
    let shareRecords = try await container.acceptShareInvitations(from: [metadata])

    print("Accepted share from: \(metadata.ownerIdentity.nameComponents?.formatted() ?? "Unknown")")

    // The shared objects will automatically appear via Core Data sync
}
```

### Pattern 3: Check if User is Owner or Participant

```swift
func checkUserRole(for share: CKShare) async throws -> UserRole {
    let container = CKContainer(identifier: "iCloud.com.yourcompany.YourApp")

    // Get current user ID
    let userRecordID = try await container.userRecordID()

    // Check if user is owner
    if share.owner.userRecordID == userRecordID {
        return .owner
    }

    // Check if user is participant
    if share.participants.contains(where: { $0.userIdentity.userRecordID == userRecordID }) {
        return .participant
    }

    return .none
}

enum UserRole {
    case owner
    case participant
    case none
}
```

---

## Handling Permissions

### Pattern 1: Check User's Permission Level

```swift
func getUserPermission(for share: CKShare) async -> CKShare.ParticipantPermission {
    let container = CKContainer(identifier: "iCloud.com.yourcompany.YourApp")

    guard let userRecordID = try? await container.userRecordID() else {
        return .none
    }

    // Find participant matching current user
    if let participant = share.participants.first(where: {
        $0.userIdentity.userRecordID == userRecordID
    }) {
        return participant.permission
    }

    return .none
}
```

### Pattern 2: Set Different Permission Levels

```swift
func configureSharePermissions(_ share: CKShare, allowEditing: Bool) {
    if allowEditing {
        // Allow participants to edit
        share.publicPermission = .readWrite
    } else {
        // Participants can only view
        share.publicPermission = .readOnly
    }

    // For private shares (invitation only)
    share.publicPermission = .none
}
```

### Pattern 3: UI Based on Permissions

```swift
struct ItemView: View {
    @ObservedObject var item: Item
    @State private var canEdit: Bool = false

    var body: some View {
        VStack {
            Text(item.name)

            if canEdit {
                Button("Edit") { /* ... */ }
            } else {
                Text("Read-only")
            }
        }
        .onAppear {
            checkPermissions()
        }
    }

    func checkPermissions() {
        guard let share = getShare(for: item) else {
            // Not shared, user owns it
            canEdit = true
            return
        }

        Task {
            let permission = await getUserPermission(for: share)
            await MainActor.run {
                canEdit = (permission == .readWrite)
            }
        }
    }
}
```

---

## Common Patterns

### Pattern 1: SwiftUI List with Share Indicators

```swift
struct ItemsListView: View {
    @FetchRequest(sortDescriptors: [])
    var items: FetchedResults<Item>

    var body: some View {
        List(items) { item in
            HStack {
                Text(item.name)
                Spacer()

                if isShared(item) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    func isShared(_ item: Item) -> Bool {
        // Check if item has associated share
        return PersistenceController.shared.getShare(for: item) != nil
    }
}
```

### Pattern 2: Context Menu with Share Option

```swift
.contextMenu {
    Button {
        shareItem(item)
    } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    if isShared(item) {
        Button(role: .destructive) {
            stopSharing(item)
        } label: {
            Label("Stop Sharing", systemImage: "person.2.slash")
        }
    }
}
```

### Pattern 3: Show Participants

```swift
func getParticipants(for object: NSManagedObject) -> [CKShare.Participant] {
    guard let share = getShare(for: object) else {
        return []
    }

    return share.participants
}

struct ParticipantsView: View {
    let participants: [CKShare.Participant]

    var body: some View {
        List(participants, id: \.userIdentity.userRecordID) { participant in
            HStack {
                Text(participant.userIdentity.nameComponents?.formatted() ?? "Unknown")

                Spacer()

                if participant.role == .owner {
                    Text("Owner")
                        .foregroundColor(.secondary)
                } else {
                    Text(participant.permission == .readWrite ? "Can Edit" : "View Only")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

### Pattern 4: Real-time Sync Notification

```swift
// In your PersistenceController
init() {
    // ... setup code ...

    // Observe remote changes
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleRemoteChange),
        name: .NSPersistentStoreRemoteChange,
        object: nil
    )
}

@objc func handleRemoteChange(_ notification: Notification) {
    DispatchQueue.main.async {
        // Show a banner or update UI
        print("Changes received from iCloud")

        // Post custom notification for UI to react
        NotificationCenter.default.post(
            name: .dataDidSync,
            object: nil
        )
    }
}

extension Notification.Name {
    static let dataDidSync = Notification.Name("dataDidSync")
}
```

### Pattern 5: Conflict Resolution Strategy

```swift
// Custom merge policy for conflict resolution
class CustomMergePolicy: NSMergePolicy {
    override func resolve(constraintConflicts list: [NSConstraintConflict]) throws {
        for conflict in list {
            // Option 1: Keep newest version
            if let newestObject = conflict.databaseObject {
                conflict.conflictingObjects.forEach { object in
                    if let modifiedDate = object.value(forKey: "modifiedAt") as? Date,
                       let dbModifiedDate = newestObject.value(forKey: "modifiedAt") as? Date {
                        if modifiedDate > dbModifiedDate {
                            // Local version is newer, keep it
                        } else {
                            // Database version is newer, use it
                        }
                    }
                }
            }

            // Option 2: Merge specific properties
            // Option 3: Create duplicate and let user decide
        }

        // Call super to complete resolution
        try super.resolve(constraintConflicts: list)
    }
}
```

---

## Best Practices

### ✅ DO:
- Always check `canShare` before presenting share UI
- Handle errors gracefully (user might not be signed into iCloud)
- Test on real devices with different iCloud accounts
- Use persistent history tracking
- Set appropriate merge policies
- Show visual indicators for shared items
- Handle incoming shares via URL

### ❌ DON'T:
- Don't test in the simulator (CloudKit sharing won't work)
- Don't force-share without user permission
- Don't assume iCloud is always available
- Don't forget to save context after creating shares
- Don't ignore merge conflicts
- Don't share sensitive data without encryption

---

## Debugging Tips

### Check CloudKit Dashboard
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container
3. View data in Private/Shared databases
4. Check for errors in CloudKit logs

### Console Logging
```swift
// Enable CloudKit logging
// Add to scheme environment variables:
// -com.apple.CoreData.CloudKitDebug 3
// -com.apple.CoreData.Logging.oslog 1
```

### Common Error Messages

**"Zone not found"**
- CloudKit creates zones lazily
- Create an item first, wait, then try sharing

**"Not authenticated"**
- User not signed into iCloud
- Check Settings → [Name] → iCloud

**"Network unavailable"**
- No internet connection
- Changes will sync when connection restored

**"Quota exceeded"**
- Free tier limits reached
- CloudKit has storage/request limits

---

## Additional Resources

- **Sample Project**: See `SharedRemindersApp` for a complete working example
- **Apple Docs**: [CloudKit Sharing](https://developer.apple.com/documentation/cloudkit/shared_records)
- **WWDC Sessions**: Search for "CloudKit" on Apple Developer

---

**Remember**: CloudKit sharing is complex but incredibly powerful. Start with this simple reminders app to understand the patterns, then adapt them to your own app's needs!
