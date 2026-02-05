import SwiftUI
import SwiftData
import Charts

struct FutureValueSimulatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var annualInterestRate: Double = 10
    @State private var timeHorizon: Double = 10
    @State private var selectedDataPoint: ProjectionDataPoint?
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var currentSavings: Double {
        habits.filter { $0.isActive }.reduce(0) { $0 + $1.totalSaved }
    }
    
    private var dailySavingsRate: Double {
        habits.filter { $0.isActive }.reduce(0) { $0 + $1.dailyCost }
    }
    
    private var projectionData: [ProjectionDataPoint] {
        InvestmentEngine.generateProjection(
            currentSavings: currentSavings,
            dailySavingsRate: dailySavingsRate,
            annualRate: annualInterestRate,
            years: Int(timeHorizon),
            dataPointsCount: 20
        )
    }
    
    private var finalValue: Double {
        InvestmentEngine.futureValueWithContributions(
            principal: currentSavings,
            regularContribution: dailySavingsRate,
            annualRate: annualInterestRate,
            years: timeHorizon
        )
    }
    
    private var totalContributions: Double {
        currentSavings + (dailySavingsRate * 365 * timeHorizon)
    }
    
    private var interestEarned: Double {
        finalValue - totalContributions
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                summarySection
                
                // Interactive Chart
                chartSection
                
                // Sliders
                controlsSection
                
                // Breakdown
                breakdownSection
                
                // Investment Tips
                tipsSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Simulator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            annualInterestRate = userSettings.annualInterestRate
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Final amount",
                value: userSettings.formatCompactCurrency(finalValue),
                subtitle: "in \(Int(timeHorizon)) years",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            SummaryCard(
                title: "Interest earned",
                value: userSettings.formatCompactCurrency(interestEarned),
                subtitle: "\(Int(annualInterestRate))% annual",
                icon: "percent",
                color: .orange
            )
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth forecast")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(projectionData) { point in
                    // Savings without interest (area)
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Amount", point.savings)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Total with interest (line)
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Amount", point.withInterest)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    // Savings line
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Savings", point.savings)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                
                // Selected point annotation
                if let selected = selectedDataPoint {
                    PointMark(
                        x: .value("Year", selected.year),
                        y: .value("Amount", selected.withInterest)
                    )
                    .foregroundStyle(Color.green)
                    .symbolSize(150)
                    
                    RuleMark(x: .value("Year", selected.year))
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text("Y\(year)")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(userSettings.formatCompactCurrency(amount))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    if let year: Int = proxy.value(atX: x) {
                                        selectedDataPoint = projectionData.first { $0.year == year }
                                        HapticManager.shared.selection()
                                    }
                                }
                                .onEnded { _ in
                                    selectedDataPoint = nil
                                }
                        )
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .green, label: "With interest")
                LegendItem(color: .blue, label: "Without interest")
            }
            .font(.caption)
            
            // Selected Point Details
            if let selected = selectedDataPoint {
                VStack(spacing: 8) {
                    HStack {
                        Text("Year \(selected.year)")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Total amount:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(userSettings.formatCurrency(selected.withInterest))
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Interest earned:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(userSettings.formatCurrency(selected.interestEarned))
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Interest Rate Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Annual return")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(annualInterestRate))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Slider(value: $annualInterestRate, in: 1...25, step: 1) { editing in
                    if !editing {
                        HapticManager.shared.sliderChanged()
                    }
                }
                .tint(.orange)
                
                HStack {
                    Text("Conservative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Aggressive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Time Horizon Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Investment horizon")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(timeHorizon)) years")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Slider(value: $timeHorizon, in: 1...30, step: 1) { editing in
                    if !editing {
                        HapticManager.shared.sliderChanged()
                    }
                }
                .tint(.blue)
                
                HStack {
                    Text("1 year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("30 years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Breakdown Section
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                BreakdownRow(
                    label: "Current savings",
                    value: userSettings.formatCurrency(currentSavings),
                    color: .primary
                )
                
                BreakdownRow(
                    label: "Future contributions",
                    value: "+ " + userSettings.formatCurrency(dailySavingsRate * 365 * timeHorizon),
                    subtitle: "\(userSettings.formatCurrency(dailySavingsRate))/day × \(Int(timeHorizon)) years",
                    color: .blue
                )
                
                BreakdownRow(
                    label: "Compound interest",
                    value: "+ " + userSettings.formatCurrency(interestEarned),
                    subtitle: "The power of compound interest",
                    color: .orange
                )
                
                Divider()
                
                BreakdownRow(
                    label: "Total in \(Int(timeHorizon)) years",
                    value: userSettings.formatCurrency(finalValue),
                    color: .green,
                    isTotal: true
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Investment insights")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                TipCard(
                    icon: "lightbulb.fill",
                    title: "Rule of 72",
                    description: "At \(Int(annualInterestRate))% return your money doubles in \(72 / Int(max(1, annualInterestRate))) years.",
                    color: .yellow
                )
                
                TipCard(
                    icon: "clock.fill",
                    title: "Start earlier",
                    description: "Starting 5 years earlier would give you an extra \(userSettings.formatCompactCurrency(InvestmentEngine.futureValueWithContributions(principal: currentSavings, regularContribution: dailySavingsRate, annualRate: annualInterestRate, years: timeHorizon + 5) - finalValue)).",
                    color: .blue
                )
                
                TipCard(
                    icon: "arrow.up.right",
                    title: "Consistency is key",
                    description: "Your daily \(userSettings.formatCurrency(dailySavingsRate)) becomes \(userSettings.formatCurrency(dailySavingsRate * 365)) per year!",
                    color: .green
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct BreakdownRow: View {
    let label: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(isTotal ? .headline : .subheadline)
                    .foregroundColor(isTotal ? .primary : .secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            Text(value)
                .font(isTotal ? .title3 : .subheadline)
                .fontWeight(isTotal ? .bold : .semibold)
                .foregroundColor(color)
        }
    }
}

struct TipCard: View {
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
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        FutureValueSimulatorView()
            .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
    }
}
