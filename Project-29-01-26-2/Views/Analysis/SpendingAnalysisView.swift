import SwiftUI
import SwiftData
import Charts

struct SpendingAnalysisView: View {
    @Query(sort: \Habit.startDate) private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var selectedHabit: Habit?
    @State private var animateChart = false
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }
    
    private var totalYearlyCost: Double {
        activeHabits.reduce(0) { $0 + $1.yearlyCost }
    }
    
    private var chartData: [HabitChartData] {
        activeHabits.map { habit in
            HabitChartData(
                id: habit.id,
                name: habit.name,
                value: habit.yearlyCost,
                color: Color(hex: habit.colorHex)
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if activeHabits.isEmpty {
                        emptyStateView
                    } else {
                        // Summary Header
                        summaryHeaderSection
                        
                        // Pie Chart
                        pieChartSection
                        
                        // Habit Breakdown List
                        habitBreakdownSection
                        
                        // Time Comparison
                        timeComparisonSection
                        
                        // Insights
                        insightsSection
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Spending Analysis")
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateChart = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No data to analyze")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add habits to see spending breakdown")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Summary Header
    
    private var summaryHeaderSection: some View {
        VStack(spacing: 8) {
            Text("Annual cost of bad habits")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(userSettings.formatCurrency(totalYearlyCost))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.red)
            
            Text("That's \(userSettings.formatCurrency(totalYearlyCost / 12))/month you're now saving!")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Pie Chart
    
    private var pieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending distribution")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                Chart(chartData) { data in
                    SectorMark(
                        angle: .value("Cost", animateChart ? data.value : 0),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(data.color)
                    .opacity(selectedHabit == nil || selectedHabit?.id == data.id ? 1 : 0.3)
                }
                .chartLegend(.hidden)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        let frame = geometry[chartProxy.plotFrame!]
                        VStack {
                            if let habit = selectedHabit {
                                Text(habit.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(userSettings.formatCurrency(habit.yearlyCost))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: habit.colorHex))
                                Text("\(percentageForHabit(habit))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Total")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(userSettings.formatCurrency(totalYearlyCost))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("/year")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
                .frame(height: 280)
                .onTapGesture {
                    selectedHabit = nil
                    HapticManager.shared.selection()
                }
            }
            
            // Legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(chartData) { data in
                    Button {
                        if selectedHabit?.id == data.id {
                            selectedHabit = nil
                        } else {
                            selectedHabit = activeHabits.first { $0.id == data.id }
                        }
                        HapticManager.shared.selection()
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)
                            
                            Text(data.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(percentageForData(data))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedHabit?.id == data.id ? data.color.opacity(0.2) : Color.clear)
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Habit Breakdown
    
    private var habitBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed breakdown")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(activeHabits.sorted { $0.yearlyCost > $1.yearlyCost }) { habit in
                HabitBreakdownRow(habit: habit, settings: userSettings, totalCost: totalYearlyCost)
            }
        }
    }
    
    // MARK: - Time Comparison
    
    private var timeComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison by period")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                CostComparisonRow(
                    period: "Per day",
                    amount: userSettings.formatCurrency(totalYearlyCost / 365),
                    icon: "sun.max.fill",
                    color: .yellow
                )
                
                CostComparisonRow(
                    period: "Per week",
                    amount: userSettings.formatCurrency(totalYearlyCost / 52),
                    icon: "calendar",
                    color: .blue
                )
                
                CostComparisonRow(
                    period: "Per month",
                    amount: userSettings.formatCurrency(totalYearlyCost / 12),
                    icon: "calendar.badge.clock",
                    color: .purple
                )
                
                CostComparisonRow(
                    period: "Per year",
                    amount: userSettings.formatCurrency(totalYearlyCost),
                    icon: "calendar.circle.fill",
                    color: .red
                )
                
                Divider()
                
                CostComparisonRow(
                    period: "Over 5 years",
                    amount: userSettings.formatCurrency(totalYearlyCost * 5),
                    icon: "5.circle.fill",
                    color: .orange
                )
                
                CostComparisonRow(
                    period: "Over 10 years",
                    amount: userSettings.formatCurrency(totalYearlyCost * 10),
                    icon: "10.circle.fill",
                    color: .green
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let biggestDrain = activeHabits.max(by: { $0.yearlyCost < $1.yearlyCost }) {
                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Most expensive habit",
                    description: "\(biggestDrain.name) cost you \(userSettings.formatCurrency(biggestDrain.yearlyCost))/year — that's \(percentageForHabit(biggestDrain))% of all spending!",
                    color: .red
                )
            }
            
            InsightCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Investment potential",
                description: "If you invest \(userSettings.formatCurrency(totalYearlyCost))/year at 10% annual return, in 10 years you'll have \(userSettings.formatCompactCurrency(InvestmentEngine.futureValueWithContributions(principal: 0, regularContribution: totalYearlyCost / 365, annualRate: 10, years: 10)))!",
                color: .green
            )
            
            InsightCard(
                icon: "hourglass",
                title: "Value of time",
                description: "That \(userSettings.formatCurrency(totalYearlyCost)) per year is \(Int(totalYearlyCost / 12)) \(userSettings.currency.symbol) per month now working for you!",
                color: .orange
            )
        }
    }
    
    // MARK: - Helpers
    
    private func percentageForHabit(_ habit: Habit) -> Int {
        guard totalYearlyCost > 0 else { return 0 }
        return Int((habit.yearlyCost / totalYearlyCost) * 100)
    }
    
    private func percentageForData(_ data: HabitChartData) -> Int {
        guard totalYearlyCost > 0 else { return 0 }
        return Int((data.value / totalYearlyCost) * 100)
    }
}

// MARK: - Chart Data Model

struct HabitChartData: Identifiable {
    let id: UUID
    let name: String
    let value: Double
    let color: Color
}

// MARK: - Supporting Views

struct HabitBreakdownRow: View {
    let habit: Habit
    let settings: UserSettings
    let totalCost: Double
    
    private var percentage: Double {
        guard totalCost > 0 else { return 0 }
        return habit.yearlyCost / totalCost
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: habit.iconName)
                    .foregroundColor(Color(hex: habit.colorHex))
                    .frame(width: 24)
                
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(settings.formatCurrency(habit.yearlyCost))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.tertiarySystemBackground))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: habit.colorHex))
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct CostComparisonRow: View {
    let period: String
    let amount: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(period)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(amount)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    SpendingAnalysisView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
