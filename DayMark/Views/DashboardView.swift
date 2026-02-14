import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.name) private var profiles: [Profile]
    @State private var showingAddProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if profiles.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(profiles) { profile in
                            NavigationLink(destination: ProfileDetailView(profile: profile)) {
                                ProfileCard(profile: profile)
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
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddProfileView()
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
            Button("Add Profile") {
                showingAddProfile = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#6A4C93"))
            Spacer()
        }
        .padding()
    }
}
