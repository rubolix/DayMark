import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @State private var showingAddSubject = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if subjects.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(subjects) { subject in
                            NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                SubjectCard(subject: subject)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DayMark")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: DataSettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSubject = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Nothing to track yet")
                .font(.title2)
                .fontWeight(.medium)
            Text("Tap + to add a person or pet\nand start tracking.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Subject") {
                showingAddSubject = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#6A4C93"))
            Spacer()
        }
        .padding()
    }
}
