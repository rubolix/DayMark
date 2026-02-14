import SwiftUI
import SwiftData

struct ProfileDetailView: View {
    let profile: Profile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allTrackers: [Tracker]
    @State private var showingAddTracker = false
    @State private var showingEditProfile = false
    @State private var showingDeleteAlert = false
    @State private var showingArchivedTrackers = false

    private var profileTrackers: [Tracker] {
        allTrackers.filter { $0.profile?.persistentModelID == profile.persistentModelID }
    }

    var activeTrackers: [Tracker] {
        profileTrackers.filter { !$0.isArchived }.sorted { $0.name < $1.name }
    }

    var archivedTrackers: [Tracker] {
        profileTrackers.filter { $0.isArchived }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    ProfileIcon(emoji: profile.emoji, photoData: profile.photoData, colorHex: profile.colorHex, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(activeTrackers.count) active tracker\(activeTrackers.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if activeTrackers.isEmpty {
                Section {
                    Text("No active trackers. Tap ⋯ to add one.")
                        .foregroundStyle(.secondary)
                }
            }

            if !activeTrackers.isEmpty {
                Section("Active Trackers") {
                    ForEach(activeTrackers) { tracker in
                        NavigationLink(destination: TrackerDetailView(tracker: tracker)) {
                            TrackerListRow(tracker: tracker)
                        }
                    }
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddTracker = true
                    } label: {
                        Label("Add Tracker", systemImage: "plus")
                    }
                    Button {
                        showingEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    if !archivedTrackers.isEmpty {
                        Button {
                            showingArchivedTrackers = true
                        } label: {
                            Label("Archived Trackers (\(archivedTrackers.count))", systemImage: "archivebox")
                        }
                    }
                    Divider()
                    Button {
                        profile.isArchived = true
                        for tracker in profileTrackers {
                            NotificationManager.removeReminders(for: tracker)
                        }
                        SharedModelContainer.saveAndReloadWidgets(modelContext)
                        dismiss()
                    } label: {
                        Label("Archive Profile", systemImage: "archivebox")
                    }
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Profile", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddTracker) {
            AddTrackerView(profile: profile)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profile: profile)
        }
        .sheet(isPresented: $showingArchivedTrackers) {
            ArchivedTrackersSheet(trackers: archivedTrackers)
        }
        .alert("Delete \(profile.name)?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(profile)
                SharedModelContainer.saveAndReloadWidgets(modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all trackers and entries for \(profile.name). This cannot be undone.")
        }
    }
}

struct TrackerListRow: View {
    let tracker: Tracker
    @Query private var allEntries: [Entry]

    init(tracker: Tracker) {
        self.tracker = tracker
        self._allEntries = Query(sort: \Entry.date, order: .reverse)
    }

    private var trackerEntries: [Entry] {
        allEntries.filter { $0.tracker?.id == tracker.id }
    }

    private var todayTotal: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let todayEntries = trackerEntries.filter { cal.isDate($0.date, inSameDayAs: today) }
        let sum = Int(todayEntries.reduce(0) { $0 + $1.value })
        if tracker.unit.isEmpty {
            return "\(sum) today"
        }
        return "\(sum) \(tracker.unit) today"
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: tracker.colorHex))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(tracker.name)
                    .font(.body)
                Text(tracker.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if tracker.isArchived {
                Text("PAUSED")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.15))
                    .clipShape(Capsule())
            } else if tracker.type == .count {
                Text(todayTotal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(trackerEntries.count) entries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ArchivedTrackersSheet: View {
    let trackers: [Tracker]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if trackers.isEmpty {
                    Text("No archived trackers.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(trackers) { tracker in
                        HStack {
                            Circle()
                                .fill(Color(hex: tracker.colorHex))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tracker.name)
                                    .font(.body)
                                Text("\(tracker.entries.count) entries · \(tracker.type.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Unarchive") {
                                tracker.isArchived = false
                                if tracker.reminderCadence != .none {
                                    NotificationManager.scheduleReminders(for: tracker)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .navigationTitle("Archived Trackers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
