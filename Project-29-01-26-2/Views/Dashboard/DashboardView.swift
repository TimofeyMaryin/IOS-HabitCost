import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var showingLogEntry = false
    @State private var animateMetrics = false
    @State private var showingCleanDayConfirmation = false
    @State private var showingNoHabitsAlert = false
    @State private var cleanDaySavedAmount: Double = 0
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }
    
    private var totalDaysClean: Int {
        activeHabits.map { $0.currentStreak }.min() ?? 0
    }
    
    private var totalSaved: Double {
        activeHabits.reduce(0) { $0 + $1.totalSaved }
    }
    
    private var dailySavingsRate: Double {
        activeHabits.reduce(0) { $0 + $1.dailyCost }
    }
    
    private var futureWealth: Double {
        InvestmentEngine.futureValue(
            principal: totalSaved,
            annualRate: userSettings.annualInterestRate,
            compoundingFrequency: 12,
            years: 1
        ) - totalSaved
    }
    
    private var projectedAnnualSavings: Double {
        dailySavingsRate * 365
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Stats Section
                    heroSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Today's Progress
                    todayProgressSection
                    
                    // Investment Preview
                    investmentPreviewSection
                    
                    // Active Habits Summary
                    if !habits.isEmpty {
                        habitsOverviewSection
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingLogEntry = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingLogEntry) {
                LogEntryView()
            }
            .alert("Clean day logged!", isPresented: $showingCleanDayConfirmation) {
                Button("Great!") {}
            } message: {
                Text("Today you saved \(userSettings.formatCurrency(cleanDaySavedAmount)). Keep it up!")
            }
            .alert("No active habits", isPresented: $showingNoHabitsAlert) {
                Button("Add habit") {
                    // Navigate to habits
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Add a habit first that you want to track.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateMetrics = true
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Main Streak Display
            VStack(spacing: 8) {
                Text("\(totalDaysClean)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.streakGradient)
                    .scaleEffect(animateMetrics ? 1 : 0.5)
                    .opacity(animateMetrics ? 1 : 0)
                
                Text("Days without relapse")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            
            // Three Key Metrics
            HStack(spacing: 12) {
                MetricCard(
                    icon: "banknote.fill",
                    title: "Saved",
                    value: userSettings.formatCurrency(totalSaved),
                    color: .green,
                    animate: animateMetrics
                )
                
                MetricCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Future wealth",
                    value: userSettings.formatCurrency(futureWealth),
                    subtitle: "Interest in 1 year",
                    color: .orange,
                    animate: animateMetrics
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Clean day",
                    color: .green
                ) {
                    logCleanDay()
                }
                
                QuickActionButton(
                    icon: "exclamationmark.triangle.fill",
                    title: "Relapse",
                    color: .red
                ) {
                    showingLogEntry = true
                }
            }
        }
    }
    
    // MARK: - Today's Progress
    
    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userSettings.formatCurrency(dailySavingsRate))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("saved today thanks to willpower")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
            )
        }
    }
    
    // MARK: - Investment Preview
    
    private var investmentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Investment forecast")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink {
                    FutureValueSimulatorView()
                } label: {
                    Text("Details")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    ProjectionRow(
                        title: "5 years",
                        value: userSettings.formatCompactCurrency(
                            InvestmentEngine.futureValueWithContributions(
                                principal: totalSaved,
                                regularContribution: dailySavingsRate,
                                annualRate: userSettings.annualInterestRate,
                                years: 5
                            )
                        ),
                        icon: "5.circle.fill"
                    )
                    
                    ProjectionRow(
                        title: "10 years",
                        value: userSettings.formatCompactCurrency(
                            InvestmentEngine.futureValueWithContributions(
                                principal: totalSaved,
                                regularContribution: dailySavingsRate,
                                annualRate: userSettings.annualInterestRate,
                                years: 10
                            )
                        ),
                        icon: "10.circle.fill"
                    )
                    
                    ProjectionRow(
                        title: "20 years",
                        value: userSettings.formatCompactCurrency(
                            InvestmentEngine.futureValueWithContributions(
                                principal: totalSaved,
                                regularContribution: dailySavingsRate,
                                annualRate: userSettings.annualInterestRate,
                                years: 20
                            )
                        ),
                        icon: "20.circle.fill"
                    )
                }
                
                Text("At \(Int(userSettings.annualInterestRate))% annual return")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Habits Overview
    
    private var habitsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active habits")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink {
                    HabitManagerView()
                } label: {
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            ForEach(activeHabits.prefix(3)) { habit in
                HabitRowCard(habit: habit, settings: userSettings)
            }
        }
    }
    
    // MARK: - Actions
    
    private func logCleanDay() {
        guard !activeHabits.isEmpty else {
            showingNoHabitsAlert = true
            HapticManager.shared.warning()
            return
        }
        
        var totalAmount: Double = 0
        
        for habit in activeHabits {
            let entry = LogEntry(
                type: .saved,
                amount: habit.dailyCost,
                note: "Clean day"
            )
            entry.habit = habit
            modelContext.insert(entry)
            totalAmount += habit.dailyCost
        }
        
        cleanDaySavedAmount = totalAmount
        showingCleanDayConfirmation = true
        HapticManager.shared.logSaved()
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    var animate: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .scaleEffect(animate ? 1 : 0.9)
        .opacity(animate ? 1 : 0)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
            )
        }
    }
}

struct ProjectionRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HabitRowCard: View {
    let habit: Habit
    let settings: UserSettings
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundColor(Color(hex: habit.colorHex))
                .frame(width: 44, height: 44)
                .background(Color(hex: habit.colorHex).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(habit.currentStreak) days • \(settings.formatCurrency(habit.totalSaved)) saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(settings.formatCurrency(habit.dailyCost))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
