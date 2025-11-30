# Shared Reminders App - CloudKit Sharing Tutorial

A complete iOS app demonstrating **Core Data + CloudKit sharing** for collaborative task management. This app serves as an educational example for implementing iCloud sharing in your own iOS apps.

## Features

- ✅ Create, edit, and delete reminders
- ✅ Check off completed tasks
- ✅ Real-time sync across all your devices via iCloud
- ✅ **Share reminders with other users** - they can view and edit collaboratively
- ✅ Comprehensive code comments explaining every aspect of CloudKit sharing
- ✅ Production-ready architecture

## What You'll Learn

This app demonstrates:

1. **Core Data Setup** - How to structure your data models for CloudKit
2. **NSPersistentCloudKitContainer** - Automatic iCloud syncing
3. **Creating Shares** - Using `UICloudSharingController` to share data
4. **Managing Shares** - Adding/removing participants, setting permissions
5. **Accepting Shares** - Handling incoming share invitations
6. **Bidirectional Sync** - Changes from any participant sync to everyone
7. **Conflict Resolution** - How Core Data merges concurrent edits

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Your App                                │
├─────────────────────────────────────────────────────────────────┤
│  ContentView.swift          - Main UI with reminders list       │
│  PersistenceController.swift - Core Data + CloudKit management  │
│  CloudKitSharingView.swift   - Share sheet UI wrapper          │
│  ShareAcceptanceHandler.swift - Incoming share handling        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              NSPersistentCloudKitContainer                      │
│  (Automatically syncs Core Data ↔ CloudKit)                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        CloudKit                                 │
├──────────────────────┬──────────────────────┬──────────────────┤
│   Private Database   │   Shared Database    │  Public Database │
│   (user's own data)  │ (shared with others) │ (everyone reads) │
└──────────────────────┴──────────────────────┴──────────────────┘
```

## Setup Instructions

### Step 1: Create Xcode Project

1. Open Xcode
2. Create a new project: **File → New → Project**
3. Select **iOS → App**
4. Configure the project:
   - Product Name: `SharedRemindersApp`
   - Team: Select your Apple Developer team
   - Organization Identifier: `com.yourcompany` (use your actual identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Check **Use Core Data**
   - ✅ Check **Host in CloudKit**
5. Save the project

### Step 2: Add Source Files

Replace the default files with the ones from this repository:

1. **Delete** the default `ContentView.swift` and `Persistence.swift` that Xcode created
2. **Add** all `.swift` files from the `SharedRemindersApp` folder to your project
3. **Replace** the default Core Data model:
   - Delete the `.xcdatamodeld` file Xcode created
   - Add the `SharedRemindersApp.xcdatamodeld` folder from this repository

**IMPORTANT - Core Data Model Setup:**

The `.xcdatamodeld` folder structure I provided should work directly, BUT if you encounter any issues or want to create it manually in Xcode:

1. In Xcode, select the `.xcdatamodeld` file
2. Click **Editor → Add Entity** (or click the + button at the bottom)
3. Name the entity `ReminderItem`
4. Add the following attributes (click + under Attributes):

| Attribute Name | Type   | Optional | Default Value |
|---------------|--------|----------|---------------|
| id            | UUID   | No       | -             |
| title         | String | No       | ""            |
| isCompleted   | Boolean| No       | NO            |
| createdAt     | Date   | No       | -             |
| modifiedAt    | Date   | No       | -             |

5. Select the entity, then in the **Data Model Inspector** (right panel):
   - Class: `ReminderItem`
   - Codegen: **Class Definition** (Xcode will auto-generate the class)

### Step 3: Configure CloudKit Container

This is **CRITICAL** for iCloud sharing to work!

1. **Select your project** in the navigator (blue icon at the top)
2. Select your **app target** (not the project)
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** and add:
   - **iCloud**
   - **Background Modes**

#### Configure iCloud Capability:

Under the iCloud section:
- ✅ Check **CloudKit**
- Click the **+** button under "Containers"
- Create a new container: `iCloud.com.yourcompany.SharedRemindersApp`
  - Replace `com.yourcompany` with your actual organization identifier
- Select the container you just created

#### Configure Background Modes:

Under Background Modes:
- ✅ Check **Remote notifications**
  - This allows your app to receive push notifications when shared data changes

### Step 4: Update Container Identifiers in Code

**IMPORTANT:** Search the code for `iCloud.com.yourcompany.SharedRemindersApp` and replace it with the container identifier you created in Step 3.

Files to update:
- `PersistenceController.swift` (appears 3 times)
- `ContentView.swift` (appears 1 time)
- `ShareAcceptanceHandler.swift` (appears 1 time)

### Step 5: Configure Info.plist

Add the following key to your `Info.plist`:

1. Right-click `Info.plist` → **Open As → Source Code**
2. Add this entry inside the main `<dict>`:

```xml
<key>CKSharingSupported</key>
<true/>
```

This tells iOS that your app can handle CloudKit share URLs.

### Step 6: Test on Real Devices

**CloudKit sharing requires real devices** - it won't work in the simulator!

1. Connect your iPhone/iPad
2. In Xcode, select your device from the scheme selector
3. Build and run (⌘R)
4. **Sign into iCloud** on the device (Settings → [Your Name])

### Step 7: Test Sharing

To test sharing, you need **two devices** signed into **different iCloud accounts**:

#### Device 1 (Sharer):
1. Open the app
2. Create a reminder
3. Tap the share button (↑ icon)
4. Tap "Add People"
5. Choose how to send (Messages, Mail, AirDrop, etc.)
6. Send to Device 2

#### Device 2 (Recipient):
1. Receive the share link
2. Tap the link
3. iOS will ask "Open in SharedRemindersApp?"
4. Tap "Open"
5. The shared reminder appears!

#### Test Collaboration:
- Edit the reminder on Device 2 → changes appear on Device 1
- Check it off on Device 1 → checkbox updates on Device 2
- Delete it on either device → it disappears from both

## Code Structure Explained

### 1. Core Data Model (`SharedRemindersApp.xcdatamodeld`)

```
ReminderItem
├─ id: UUID           ← Required: Unique identifier for CloudKit
├─ title: String      ← The reminder text
├─ isCompleted: Bool  ← Completion status
├─ createdAt: Date    ← When created (for sorting)
└─ modifiedAt: Date   ← When last modified (for conflict resolution)
```

**Key Points:**
- `id` is essential for CloudKit to track objects across devices
- CloudKit uses timestamps for conflict resolution
- Keep models simple - complex relationships can be tricky with CloudKit

### 2. PersistenceController.swift

The heart of the app - manages Core Data + CloudKit integration.

**Key Methods:**
```swift
init(inMemory: Bool = false)
// Sets up NSPersistentCloudKitContainer with:
// - Persistent history tracking (required for CloudKit)
// - Remote change notifications
// - Automatic merge policy

createShare(for: ReminderItem) async throws -> (CKShare, CKContainer)
// Creates a CloudKit share for a reminder
// This is what makes an item shareable!

getShare(for: ReminderItem) -> CKShare?
// Checks if a reminder is already shared

deleteShare(_ share: CKShare) async throws
// Stops sharing (revokes all access)

acceptShare(metadata: CKShare.Metadata) async throws
// Accepts an incoming share invitation
```

**Important Configuration:**
```swift
// Enable persistent history tracking (REQUIRED for CloudKit)
description.setOption(true as NSNumber,
    forKey: NSPersistentHistoryTrackingKey)

// Enable remote change notifications
description.setOption(true as NSNumber,
    forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// Configure CloudKit container
let cloudKitOptions = NSPersistentCloudKitContainerOptions(
    containerIdentifier: "iCloud.com.yourcompany.SharedRemindersApp"
)
```

### 3. ContentView.swift

The main UI - demonstrates SwiftUI + Core Data integration.

**Key Features:**
```swift
@FetchRequest(sortDescriptors: [...])
private var reminders: FetchedResults<ReminderItem>
// Automatically fetches and monitors Core Data
// Updates UI when data changes (even from other devices!)

func shareReminder(_ reminder: ReminderItem)
// Creates/presents the share sheet
// Checks if already shared
// Creates new share if needed
```

**How @FetchRequest Works:**
1. Queries Core Data on every view update
2. Monitors for changes (local or from CloudKit)
3. Automatically refreshes the UI when data changes
4. Works seamlessly with CloudKit sync!

### 4. CloudKitSharingView.swift

SwiftUI wrapper for `UICloudSharingController`.

**What UICloudSharingController Does:**
- Shows Apple's system UI for sharing
- Handles inviting people via Messages, Mail, AirDrop, etc.
- Manages participants (add/remove people)
- Sets permissions (read-only vs. read-write)
- Generates shareable URLs with embedded CloudKit tokens

**Key Configuration:**
```swift
controller.availablePermissions = [
    .allowPrivate,    // Only invited people (not public)
    .allowReadWrite   // People can edit (not just view)
]
```

### 5. ShareAcceptanceHandler.swift

Handles incoming share invitations.

**The Flow:**
1. User B taps share URL from User A
2. iOS recognizes it's a CloudKit share
3. iOS opens your app with the URL
4. `onOpenURL` is triggered
5. `handleIncomingShare()` extracts share metadata
6. `acceptShare()` adds the data to User B's app
7. Core Data + CloudKit sync automatically!

## How CloudKit Sharing Works (Conceptual)

### Before Sharing:
```
User A's Device                      CloudKit
┌──────────────┐                    ┌─────────────┐
│  Reminders   │ ──syncs to──→      │   Private   │
│  - Task 1    │                    │  Database   │
│  - Task 2    │                    │  (only A)   │
└──────────────┘                    └─────────────┘
```

### After User A Shares Task 1:
```
User A's Device                      CloudKit
┌──────────────┐                    ┌─────────────┐
│  Reminders   │ ──syncs to──→      │   Shared    │
│  - Task 1 📤 │                    │  Database   │
│  - Task 2    │                    │ (A & B)     │
└──────────────┘                    └─────────────┘
                                           ↓
                                    ┌─────────────┐
User B's Device                     │  CKShare    │
┌──────────────┐                    │  Record     │
│  Reminders   │ ←──syncs from──    │ (metadata)  │
│  - Task 1 📥 │                    └─────────────┘
└──────────────┘
```

### When Either User Edits:
```
Edit on A or B → Core Data saves locally
                    ↓
            CloudKit syncs the change
                    ↓
          Other device receives update
                    ↓
          UI automatically refreshes
```

## Common Issues & Solutions

### Issue: "Cannot connect to CloudKit"
**Solution:** Make sure you're signed into iCloud on your device (Settings → [Your Name])

### Issue: "Sharing not available"
**Solution:** Check that:
1. You're on a real device (not simulator)
2. You're signed into iCloud
3. You have internet connectivity
4. Your app's CloudKit capability is properly configured

### Issue: Changes not syncing
**Solution:**
1. Check internet connection
2. Verify persistent history tracking is enabled
3. Check Xcode console for CloudKit errors
4. Try force-quitting and reopening the app

### Issue: "Zone not found" error
**Solution:** CloudKit creates zones on first use. Try:
1. Create a reminder
2. Wait a few seconds for CloudKit to initialize
3. Then try sharing

### Issue: Share link doesn't open app
**Solution:** Verify:
1. `CKSharingSupported` is in Info.plist
2. Container identifier matches in code and Xcode settings
3. App is installed on the receiving device

## Advanced Topics (For Your Own Apps)

### Custom Conflict Resolution

The app uses `.mergeByPropertyObjectTrumpMergePolicy` which means "newest value wins". For more control:

```swift
// Custom merge policy
class CustomMergePolicy: NSMergePolicy {
    override func resolve(constraintConflicts list: [NSConstraintConflict]) throws {
        // Your custom logic
        // E.g., combine values, prompt user, etc.
    }
}

container.viewContext.mergePolicy = CustomMergePolicy(
    merge: .mergeByPropertyObjectTrumpMergePolicyType
)
```

### Sharing Hierarchies of Objects

To share a reminder with sub-tasks:

1. Create a parent-child relationship in Core Data
2. When sharing, include all related objects:
```swift
let (_, share, container) = try await container.share(
    [reminder] + reminder.subtasks,  // Include children
    to: persistentStore
)
```

### Zone Management

CloudKit automatically creates "zones" for sharing. For advanced control:

```swift
// Access the CloudKit database directly
let container = CKContainer(identifier: "iCloud.com.yourcompany.SharedRemindersApp")
let database = container.privateCloudDatabase

// Create custom zone
let zone = CKRecordZone(zoneName: "CustomZone")
database.save(zone) { savedZone, error in
    // Handle result
}
```

### Push Notifications for Share Changes

To notify users when shared data changes:

1. Enable push notifications capability
2. Register for remote notifications
3. Handle incoming notifications:

```swift
func application(_ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

    // CloudKit sends silent notifications
    // Core Data will automatically fetch changes
    completionHandler(.newData)
}
```

## Resources

- [Apple's CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Core Data + CloudKit Guide](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [Sharing CloudKit Data](https://developer.apple.com/documentation/cloudkit/shared_records)
- [WWDC Videos on CloudKit](https://developer.apple.com/videos/all-videos/?q=cloudkit)

## License

This project is provided as an educational example. Feel free to use it as a starting point for your own apps!

## Questions?

If you're stuck, check:
1. Xcode console for error messages
2. Settings → [Your Name] → iCloud → ensure iCloud Drive is on
3. Developer.apple.com → CloudKit Dashboard to view your data

Happy coding! 🚀

---

**Remember:** CloudKit sharing is powerful but requires proper setup. Take your time with the configuration steps, and read through the code comments to understand how each piece works. Once you understand this example, you'll be able to implement sharing in your own apps!
