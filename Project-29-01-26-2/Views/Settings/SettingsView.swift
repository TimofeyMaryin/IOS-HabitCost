import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var habits: [Habit]
    @Query private var achievements: [Achievement]
    @Query private var logEntries: [LogEntry]
    
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    
    private var userSettings: UserSettings {
        if let existing = settings.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection
                
                // Currency & Investment Section
                investmentSection
                
                // Appearance Section
                appearanceSection
                
                // Data Management Section
                dataManagementSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Reset all data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your habits, entries and achievements. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Your name", text: Binding(
                        get: { userSettings.userName },
                        set: { userSettings.userName = $0 }
                    ))
                    .font(.headline)
                    
                    Text("Member since \(formattedDate(userSettings.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Investment Section
    
    private var investmentSection: some View {
        Section {
            // Currency Picker
            Picker("Currency", selection: Binding(
                get: { userSettings.currency },
                set: { userSettings.currency = $0 }
            )) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text("\(currency.symbol) \(currency.displayName)")
                        .tag(currency)
                }
            }
            
            // Interest Rate
            HStack {
                Text("Annual return")
                Spacer()
                Text("\(Int(userSettings.annualInterestRate))%")
                    .foregroundColor(.secondary)
                Stepper("", value: Binding(
                    get: { userSettings.annualInterestRate },
                    set: { 
                        userSettings.annualInterestRate = $0
                        HapticManager.shared.selection()
                    }
                ), in: 1...30, step: 1)
                .labelsHidden()
            }
            
            // Compounding Frequency
            Picker("Compounding", selection: Binding(
                get: { userSettings.compoundingFrequency },
                set: { userSettings.compoundingFrequency = $0 }
            )) {
                Text("Daily (365)").tag(365)
                Text("Monthly (12)").tag(12)
                Text("Quarterly (4)").tag(4)
                Text("Annually (1)").tag(1)
            }
        } header: {
            Text("Investment settings")
        } footer: {
            Text("These settings affect forecast calculations. The S&P 500 has historically returned ~10% annually.")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section {
            Toggle("Haptic feedback", isOn: Binding(
                get: { userSettings.hapticFeedbackEnabled },
                set: { 
                    userSettings.hapticFeedbackEnabled = $0
                    if $0 {
                        HapticManager.shared.success()
                    }
                }
            ))
        } header: {
            Text("Appearance")
        } footer: {
            Text("The app automatically supports dark mode and dynamic type based on system settings.")
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        Section {
            // Statistics
            HStack {
                Label("Habits tracked", systemImage: "list.bullet")
                Spacer()
                Text("\(habits.count)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Log entries", systemImage: "doc.text")
                Spacer()
                Text("\(logEntries.count)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Achievements", systemImage: "trophy")
                Spacer()
                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .foregroundColor(.secondary)
            }
            
            // Reset Data
            Button(role: .destructive) {
                showingResetConfirmation = true
                HapticManager.shared.warning()
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        } header: {
            Text("Data management")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Label("About", systemImage: "info.circle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Actions
    
    private func resetAllData() {
        habits.forEach { modelContext.delete($0) }
        achievements.forEach { modelContext.delete($0) }
        logEntries.forEach { modelContext.delete($0) }
        
        // Reset settings but keep
        userSettings.userName = "User"
        userSettings.annualInterestRate = 10.0
        userSettings.currency = .rub
        
        HapticManager.shared.error()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("HabitCost")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Future wealth tracker")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("HabitCost helps you visualize the true cost of bad habits by tracking money saved and forecasting future wealth through compound interest calculations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Every day without a relapse you're not just saving money — you're building the foundation for financial freedom.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Investment simulator", description: "Forecast savings growth with compound interest")
                        FeatureRow(icon: "trophy.fill", title: "Goal tracking", description: "Set and reach financial milestones")
                        FeatureRow(icon: "chart.pie.fill", title: "Spending analysis", description: "See where your money used to go")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Important notice", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("This app is for financial tracking and motivation only. It does not provide medical advice. If you are struggling with addiction, please seek professional help.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Investment forecasts are hypothetical and do not guarantee actual returns. Past performance does not guarantee future results.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.1))
                    )
                    
                    // Copyright
                    Text("© 2026 HabitCost. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
