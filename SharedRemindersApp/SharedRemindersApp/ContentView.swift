//
//  ContentView.swift
//  SharedRemindersApp
//
//  Main view that displays the list of reminders and allows user interactions.
//  This view demonstrates SwiftUI + Core Data integration with real-time updates.
//

import SwiftUI
import CoreData
import CloudKit

struct ContentView: View {
    // MARK: - Environment

    /// Access to the Core Data managed object context from the environment
    /// This is injected in the App file
    @Environment(\.managedObjectContext) private var viewContext

    /// Access to the persistence controller to call sharing methods
    @StateObject private var persistenceController = PersistenceController.shared

    // MARK: - Fetch Request

    /// @FetchRequest automatically fetches and monitors Core Data objects
    /// It automatically updates the view when data changes (even from iCloud!)
    ///
    /// We fetch all ReminderItem objects, sorted by creation date (newest first)
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ReminderItem.createdAt, ascending: false)
        ],
        animation: .default
    )
    private var reminders: FetchedResults<ReminderItem>

    // MARK: - State

    /// Controls whether the "Add Reminder" sheet is shown
    @State private var showingAddReminder = false

    /// The text input for a new reminder
    @State private var newReminderTitle = ""

    /// The currently selected reminder for sharing
    @State private var selectedReminderForSharing: ReminderItem?

    /// Controls whether the sharing sheet is shown
    @State private var showingShareSheet = false

    /// The CloudKit share to present in the share sheet
    @State private var activeShare: CKShare?

    /// The CloudKit container for sharing
    @State private var activeContainer: CKContainer?

    /// Controls whether an alert is shown
    @State private var showingAlert = false

    /// The alert message to display
    @State private var alertMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                if reminders.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Reminders list
                    remindersListView
                }
            }
            .navigationTitle("Shared Reminders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            // Sheet for adding a new reminder
            .sheet(isPresented: $showingAddReminder) {
                addReminderSheet
            }
            // Sheet for sharing a reminder (CloudKit share sheet)
            .sheet(isPresented: $showingShareSheet) {
                if let share = activeShare, let container = activeContainer {
                    // CloudKitSharingView is a UIKit wrapper for CloudKit's sharing UI
                    CloudKitSharingView(share: share, container: container)
                }
            }
            // Alert for errors and notifications
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - View Components

    /// Empty state view shown when there are no reminders
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Reminders Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to create your first reminder")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    /// List view showing all reminders
    private var remindersListView: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRowView(
                    reminder: reminder,
                    onToggleCompletion: {
                        // Toggle completion status
                        persistenceController.toggleCompletion(for: reminder)
                    },
                    onShare: {
                        // Share this reminder
                        shareReminder(reminder)
                    },
                    onDelete: {
                        // Delete this reminder
                        persistenceController.deleteReminder(reminder)
                    }
                )
            }
            .onDelete(perform: deleteReminders)
        }
        .listStyle(.insetGrouped)
    }

    /// Add button in the toolbar
    private var addButton: some View {
        Button {
            showingAddReminder = true
        } label: {
            Label("Add Reminder", systemImage: "plus")
        }
    }

    /// Sheet for adding a new reminder
    private var addReminderSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Reminder title", text: $newReminderTitle)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("New Reminder")
                } footer: {
                    Text("Enter a title for your reminder. It will automatically sync to iCloud.")
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newReminderTitle = ""
                        showingAddReminder = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addReminder()
                    }
                    .disabled(newReminderTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    /// Adds a new reminder
    private func addReminder() {
        let title = newReminderTitle.trimmingCharacters(in: .whitespaces)

        guard !title.isEmpty else { return }

        // Create the reminder using the persistence controller
        _ = persistenceController.createReminder(title: title)

        // Reset the form
        newReminderTitle = ""
        showingAddReminder = false
    }

    /// Deletes reminders at the specified offsets
    private func deleteReminders(offsets: IndexSet) {
        for index in offsets {
            let reminder = reminders[index]
            persistenceController.deleteReminder(reminder)
        }
    }

    /// Initiates sharing for a reminder
    ///
    /// This is the KEY method for CloudKit sharing!
    /// It creates a CKShare and presents the system share sheet.
    private func shareReminder(_ reminder: ReminderItem) {
        // Check if sharing is available (user must be signed into iCloud)
        guard persistenceController.canShare else {
            alertMessage = "CloudKit sharing is not available. Please make sure you're signed into iCloud."
            showingAlert = true
            return
        }

        // Check if this reminder is already shared
        if let existingShare = persistenceController.getShare(for: reminder) {
            // Already shared - show the existing share
            print("Reminder is already shared, presenting existing share")
            activeShare = existingShare

            // Get the CloudKit container
            let container = CKContainer(identifier: "iCloud.com.yourcompany.SharedRemindersApp")
            activeContainer = container

            showingShareSheet = true
        } else {
            // Not yet shared - create a new share
            print("Creating new share for reminder")

            Task {
                do {
                    // Create the share asynchronously
                    let (share, container) = try await persistenceController.createShare(for: reminder)

                    // Update UI on main thread
                    await MainActor.run {
                        activeShare = share
                        activeContainer = container
                        showingShareSheet = true
                    }
                } catch {
                    // Handle error
                    await MainActor.run {
                        alertMessage = "Failed to create share: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        }
    }
}

// MARK: - Reminder Row View

/// A single row in the reminders list
struct ReminderRowView: View {
    /// The reminder to display
    @ObservedObject var reminder: ReminderItem

    /// Callback when completion status is toggled
    let onToggleCompletion: () -> Void

    /// Callback when share button is tapped
    let onShare: () -> Void

    /// Callback when delete button is tapped
    let onDelete: () -> Void

    /// Access to persistence controller to check share status
    @StateObject private var persistenceController = PersistenceController.shared

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                onToggleCompletion()
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(reminder.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Reminder title
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title ?? "Untitled")
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)

                // Show if this reminder is shared
                if persistenceController.getShare(for: reminder) != nil {
                    Label("Shared", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Share button
            Button {
                onShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make entire row tappable
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
