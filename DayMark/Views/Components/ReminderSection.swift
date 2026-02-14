import SwiftUI

struct ReminderSection: View {
    @Binding var cadence: ReminderCadence
    @Binding var reminderTime: Date
    @Binding var weekday: Int
    @Binding var customDays: [Int]

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Section {
            Picker("Frequency", selection: $cadence) {
                ForEach(ReminderCadence.allCases, id: \.self) { c in
                    Text(c.rawValue).tag(c)
                }
            }

            if cadence != .none {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)

                if cadence == .weekly {
                    Picker("Day", selection: $weekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(dayNames[day - 1]).tag(day)
                        }
                    }
                }

                if cadence == .custom {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            Button {
                                if customDays.contains(day) {
                                    customDays.removeAll { $0 == day }
                                } else {
                                    customDays.append(day)
                                    customDays.sort()
                                }
                            } label: {
                                Text(dayNames[day - 1])
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(customDays.contains(day) ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(customDays.contains(day) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            switch cadence {
            case .none:
                Text("No reminders will be sent.")
            case .daily:
                Text("You'll be reminded every day.")
            case .weekdays:
                Text("Monday through Friday.")
            case .weekends:
                Text("Saturday and Sunday.")
            case .weekly:
                Text("Once per week on the selected day.")
            case .custom:
                Text("Select which days of the week to be reminded.")
            }
        }
    }
}
