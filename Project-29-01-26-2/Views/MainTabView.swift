import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            HabitManagerView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            
            FutureValueSimulatorView()
                .tabItem {
                    Label("Simulator", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            AchievementsView()
                .tabItem {
                    Label("Goals", systemImage: "trophy.fill")
                }
                .tag(3)
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .tint(.green)
    }
}

// MARK: - More View (Additional Screens Menu)

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SpendingAnalysisView()
                    } label: {
                        MoreMenuRow(
                            icon: "chart.pie.fill",
                            title: "Spending Analysis",
                            subtitle: "Which habits cost the most",
                            color: .purple
                        )
                    }
                    
                    NavigationLink {
                        ContextualStatsView()
                    } label: {
                        MoreMenuRow(
                            icon: "sparkles",
                            title: "Your Impact",
                            subtitle: "Fun facts about your savings",
                            color: .orange
                        )
                    }
                    
                    NavigationLink {
                        LogHistoryView()
                    } label: {
                        MoreMenuRow(
                            icon: "clock.arrow.circlepath",
                            title: "Log History",
                            subtitle: "All your entries",
                            color: .blue
                        )
                    }
                } header: {
                    Text("Analytics")
                }
                
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        MoreMenuRow(
                            icon: "gearshape.fill",
                            title: "Settings",
                            subtitle: "Currency, investments & more",
                            color: .gray
                        )
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

struct MoreMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log History View

struct LogHistoryView: View {
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var entries: [LogEntry]
    @Query private var settings: [UserSettings]
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var groupedEntries: [(String, [LogEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            formatDateHeader(entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            if entries.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No entries yet")
                            .font(.headline)
                        
                        Text("Your log entries will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(groupedEntries, id: \.0) { date, dayEntries in
                    Section {
                        ForEach(dayEntries) { entry in
                            LogEntryRow(entry: entry, settings: userSettings)
                        }
                    } header: {
                        Text(date)
                    }
                }
            }
        }
        .navigationTitle("History")
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    let settings: UserSettings
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type == .saved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(entry.type == .saved ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.habit?.name ?? "Unknown habit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(entry.type.displayName)
                        .font(.caption)
                        .foregroundColor(entry.type == .saved ? .green : .red)
                }
                
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(formatTime(entry.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.type == .relapse ? "-" : "+" + settings.formatCurrency(entry.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(entry.type == .saved ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
