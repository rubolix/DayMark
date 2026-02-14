import SwiftUI
import SwiftData

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportShare = false
    @State private var showingHTMLShare = false
    @State private var showingImportPicker = false
    @State private var showingImportConfirm = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsError = false
    @State private var exportFileURL: URL?
    @State private var pendingImportURL: URL?

    var body: some View {
        List {
            Section {
                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                Button {
                    exportHTML()
                } label: {
                    Label("Export as HTML", systemImage: "safari")
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
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExportShare) {
            if let url = exportFileURL {
                ShareSheet(url: url)
            }
        }
        .sheet(isPresented: $showingHTMLShare) {
            if let url = exportFileURL {
                ShareSheet(url: url)
            }
        }
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
            Text("This will add all subjects, trackers, and entries from the backup file. Existing data will not be removed.")
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
            exportFileURL = tempURL
            showingExportShare = true
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
            exportFileURL = tempURL
            showingHTMLShare = true
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
            resultMessage = "Imported \(result.subjects) subjects, \(result.trackers) trackers, and \(result.entries) entries."
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

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
