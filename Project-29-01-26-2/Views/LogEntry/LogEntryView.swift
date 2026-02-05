import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Habit> { $0.isActive }) private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var selectedHabit: Habit?
    @State private var entryType: LogEntryType = .relapse
    @State private var customAmount: String = ""
    @State private var note: String = ""
    @State private var showingConfirmation = false
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var amount: Double {
        if let custom = Double(customAmount), custom > 0 {
            return custom
        }
        return selectedHabit?.costPerUnit ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Entry Type Selector
                Picker("Entry type", selection: $entryType) {
                    Label("Relapse", systemImage: "exclamationmark.triangle.fill")
                        .tag(LogEntryType.relapse)
                    Label("Clean day", systemImage: "checkmark.circle.fill")
                        .tag(LogEntryType.saved)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Habit Selection
                        habitSelectionSection
                        
                        if entryType == .relapse {
                            // Amount Section
                            amountSection
                            
                            // Note Section
                            noteSection
                        } else {
                            // Clean Day Celebration
                            cleanDaySection
                        }
                        
                        // Impact Preview
                        impactPreviewSection
                    }
                    .padding()
                }
                
                // Log Button
                logButton
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(entryType == .relapse ? "Log relapse" : "Clean day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Entry saved", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if entryType == .relapse {
                    Text("Your relapse has been logged. Tomorrow is a new day!")
                } else {
                    Text("Great! Keep it up!")
                }
            }
            .onAppear {
                selectedHabit = habits.first
            }
        }
    }
    
    // MARK: - Habit Selection
    
    private var habitSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose habit")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if habits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("No active habits")
                        .font(.headline)
                    
                    Text("Add a habit first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(habits) { habit in
                            HabitSelectionCard(
                                habit: habit,
                                isSelected: selectedHabit?.id == habit.id,
                                settings: userSettings
                            )
                            .onTapGesture {
                                selectedHabit = habit
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Amount Section
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount spent")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(userSettings.currency.symbol)
                    .font(.title)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $customAmount)
                    .font(.system(size: 36, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                
                if let habit = selectedHabit {
                    Button {
                        customAmount = String(format: "%.2f", habit.costPerUnit)
                        HapticManager.shared.selection()
                    } label: {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (optional)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("What triggered the relapse?", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
        }
    }
    
    // MARK: - Clean Day Section
    
    private var cleanDaySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Another clean day!")
                .font(.title2)
                .fontWeight(.bold)
            
            if let habit = selectedHabit {
                Text("You saved \(userSettings.formatCurrency(habit.dailyCost)) today")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Current streak: \(habit.currentStreak + 1) days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Impact Preview
    
    private var impactPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entryType == .relapse ? "Impact on goals" : "Your progress")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                if entryType == .relapse {
                    ImpactRow(
                        icon: "arrow.clockwise",
                        title: "Streak reset",
                        value: "Back to day 1",
                        color: .red
                    )
                    
                    if amount > 0 {
                        ImpactRow(
                            icon: "minus.circle",
                            title: "Savings reduced",
                            value: "-\(userSettings.formatCurrency(amount))",
                            color: .red
                        )
                        
                        let lostInterest = InvestmentEngine.interestEarned(
                            principal: amount,
                            annualRate: userSettings.annualInterestRate,
                            years: 10
                        )
                        ImpactRow(
                            icon: "chart.line.downtrend.xyaxis",
                            title: "Lost opportunity over 10 years",
                            value: "-\(userSettings.formatCurrency(lostInterest))",
                            color: .orange
                        )
                    }
                } else {
                    if let habit = selectedHabit {
                        ImpactRow(
                            icon: "plus.circle",
                            title: "Savings today",
                            value: "+\(userSettings.formatCurrency(habit.dailyCost))",
                            color: .green
                        )
                        
                        ImpactRow(
                            icon: "flame.fill",
                            title: "New streak",
                            value: "\(habit.currentStreak + 1) days",
                            color: .orange
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Log Button
    
    private var logButton: some View {
        Button {
            logEntry()
        } label: {
            HStack {
                Image(systemName: entryType == .relapse ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                Text(entryType == .relapse ? "Log relapse" : "Confirm clean day")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(entryType == .relapse ? Color.red : Color.green)
            )
        }
        .disabled(selectedHabit == nil || (entryType == .relapse && amount <= 0))
        .padding()
    }
    
    // MARK: - Actions
    
    private func logEntry() {
        guard let habit = selectedHabit else { return }
        
        let entry = LogEntry(
            type: entryType,
            amount: entryType == .relapse ? amount : habit.dailyCost,
            note: note.isEmpty ? nil : note
        )
        
        entry.habit = habit
        modelContext.insert(entry)
        
        if entryType == .relapse {
            HapticManager.shared.logRelapse()
        } else {
            HapticManager.shared.logSaved()
        }
        
        showingConfirmation = true
    }
}

// MARK: - Supporting Views

struct HabitSelectionCard: View {
    let habit: Habit
    let isSelected: Bool
    let settings: UserSettings
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: habit.iconName)
                .font(.title)
                .foregroundColor(isSelected ? .white : Color(hex: habit.colorHex))
            
            Text(habit.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
            
            Text(settings.formatCurrency(habit.dailyCost) + "/day")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .padding()
        .frame(width: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color(hex: habit.colorHex) : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.clear : Color(hex: habit.colorHex).opacity(0.3), lineWidth: 1)
        )
    }
}

struct ImpactRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    LogEntryView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
