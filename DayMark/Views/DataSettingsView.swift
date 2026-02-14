import SwiftUI
import SwiftData

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.name) private var allProfiles: [Profile]
    @State private var showingImportPicker = false
    @State private var showingImportConfirm = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsError = false
    @State private var jsonExportURL: URL?
    @State private var htmlExportURL: URL?
    @State private var pendingImportURL: URL?

    private var archivedProfiles: [Profile] {
        allProfiles.filter { $0.isArchived }
    }

    var body: some View {
        List {
            if !archivedProfiles.isEmpty {
                Section("Archived Profiles") {
                    ForEach(archivedProfiles) { profile in
                        HStack(spacing: 12) {
                            ProfileIcon(emoji: profile.emoji, photoData: profile.photoData, colorHex: profile.colorHex, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.body)
                                Text("\(profile.trackers.count) tracker\(profile.trackers.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Reactivate") {
                                profile.isArchived = false
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .controlSize(.small)
                        }
                    }
                }
            }

            Section {
                Button {
                    exportJSON()
                } label: {
                    Label(jsonExportURL == nil ? "Export as JSON" : "Re-Export as JSON", systemImage: "doc.text")
                }
                if let url = jsonExportURL {
                    ShareLink("Share JSON Backup", item: url)
                }

                Button {
                    exportHTML()
                } label: {
                    Label(htmlExportURL == nil ? "Export as HTML" : "Re-Export as HTML", systemImage: "safari")
                }
                if let url = htmlExportURL {
                    ShareLink("Share HTML Export", item: url)
                }
            } header: {
                Text("Export")
            } footer: {
                Text("JSON exports can be re-imported. HTML exports are for viewing in a browser.")
            }

            Section {
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Import from JSON", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Import adds data from a previously exported JSON file. Existing data is not removed.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportFile(result)
        }
        .alert("Import Data?", isPresented: $showingImportConfirm) {
            Button("Import", role: .destructive) { performImport() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will add all profiles, trackers, and entries from the backup file. Existing data will not be removed.")
        }
        .alert(resultIsError ? "Error" : "Success", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }

    private func exportJSON() {
        do {
            let data = try DataManager.exportJSON(from: modelContext)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let fileName = "DayMark-Backup-\(formatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            jsonExportURL = tempURL
            resultMessage = "JSON export ready! Tap \"Share JSON Backup\" to save or send."
            resultIsError = false
            showingResult = true
        } catch {
            resultMessage = "Failed to export: \(error.localizedDescription)"
            resultIsError = true
            showingResult = true
        }
    }

    private func exportHTML() {
        do {
            let data = try DataManager.exportHTML(from: modelContext)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let fileName = "DayMark-Export-\(formatter.string(from: Date())).html"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            htmlExportURL = tempURL
            resultMessage = "HTML export ready! Tap \"Share HTML Export\" to save or send."
            resultIsError = false
            showingResult = true
        } catch {
            resultMessage = "Failed to export: \(error.localizedDescription)"
            resultIsError = true
            showingResult = true
        }
    }

    private func handleImportFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            showingImportConfirm = true
        case .failure(let error):
            resultMessage = "Failed to select file: \(error.localizedDescription)"
            resultIsError = true
            showingResult = true
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "DayMark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access the selected file."])
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            let result = try DataManager.importJSON(from: data, into: modelContext)
            resultMessage = "Imported \(result.profiles) profiles, \(result.trackers) trackers, and \(result.entries) entries."
            resultIsError = false
            showingResult = true
        } catch {
            resultMessage = "Failed to import: \(error.localizedDescription)"
            resultIsError = true
            showingResult = true
        }
        pendingImportURL = nil
    }
}
