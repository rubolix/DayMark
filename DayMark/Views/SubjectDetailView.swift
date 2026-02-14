import SwiftUI

struct SubjectDetailView: View {
    let subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTracker = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false

    var activeTrackers: [Tracker] {
        subject.trackers.filter { !$0.isArchived }.sorted { $0.name < $1.name }
    }

    var archivedTrackers: [Tracker] {
        subject.trackers.filter { $0.isArchived }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            if activeTrackers.isEmpty && archivedTrackers.isEmpty {
                Section {
                    Text("No trackers yet. Tap ⋯ to add one.")
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

            if !archivedTrackers.isEmpty {
                Section("Archived") {
                    ForEach(archivedTrackers) { tracker in
                        NavigationLink(destination: TrackerDetailView(tracker: tracker)) {
                            TrackerListRow(tracker: tracker)
                                .opacity(0.6)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(subject.emoji) \(subject.name)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddTracker = true
                    } label: {
                        Label("Add Tracker", systemImage: "plus")
                    }
                    Button {
                        showingEditSubject = true
                    } label: {
                        Label("Edit Subject", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Subject", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddTracker) {
            AddTrackerView(subject: subject)
        }
        .sheet(isPresented: $showingEditSubject) {
            EditSubjectView(subject: subject)
        }
        .alert("Delete \(subject.name)?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(subject)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete all trackers and entries for \(subject.name). This cannot be undone.")
        }
    }
}

struct TrackerListRow: View {
    let tracker: Tracker

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
            } else {
                Text("\(tracker.entries.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
