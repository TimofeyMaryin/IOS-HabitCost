import Foundation
import SwiftData

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var daysMultiplier: Double {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        }
    }
    
    /// Localized display name for UI
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var iconName: String
    var costPerUnit: Double
    var unitsPerPeriod: Double
    var frequency: HabitFrequency
    var startDate: Date
    var isActive: Bool
    var colorHex: String
    
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.habit)
    var logEntries: [LogEntry]?
    
    init(
        name: String,
        iconName: String = "flame.fill",
        costPerUnit: Double,
        unitsPerPeriod: Double = 1,
        frequency: HabitFrequency = .daily,
        startDate: Date = Date(),
        isActive: Bool = true,
        colorHex: String = "#FF6B6B"
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.costPerUnit = costPerUnit
        self.unitsPerPeriod = unitsPerPeriod
        self.frequency = frequency
        self.startDate = startDate
        self.isActive = isActive
        self.colorHex = colorHex
        self.logEntries = []
    }
    
    // MARK: - Computed Properties
    
    var dailyCost: Double {
        let totalPerPeriod = costPerUnit * unitsPerPeriod
        return totalPerPeriod / frequency.daysMultiplier
    }
    
    var weeklyCost: Double {
        return dailyCost * 7
    }
    
    var monthlyCost: Double {
        return dailyCost * 30
    }
    
    var yearlyCost: Double {
        return dailyCost * 365
    }
    
    /// Number of days since quitting the habit (including today as day 1)
    var daysSinceStart: Int {
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfStartDate, to: startOfToday)
        // +1 so the first day counts as 1, not 0
        return max(1, (components.day ?? 0) + 1)
    }
    
    /// Total savings = "clean day" entries minus "relapse" entries
    /// If no "clean day" entries — use automatic calculation by days
    var totalSaved: Double {
        guard let entries = logEntries, !entries.isEmpty else {
            // No entries — automatic calculation
            return Double(daysSinceStart) * dailyCost
        }
        
        let savedEntries = entries.filter { $0.type == .saved }
        let relapseAmount = totalRelapseAmount
        
        if savedEntries.isEmpty {
            // Only relapses — automatic calculation minus relapses
            return max(0, Double(daysSinceStart) * dailyCost - relapseAmount)
        }
        
        // Has "clean day" entries — count by entries
        let savedAmount = savedEntries.reduce(0) { $0 + $1.amount }
        return max(0, savedAmount - relapseAmount)
    }
    
    var totalRelapseAmount: Double {
        guard let entries = logEntries else { return 0 }
        return entries
            .filter { $0.type == .relapse }
            .reduce(0) { $0 + $1.amount }
    }
    
    var relapseCount: Int {
        guard let entries = logEntries else { return 0 }
        return entries.filter { $0.type == .relapse }.count
    }
    
    /// Number of "clean" entries
    var cleanDaysCount: Int {
        guard let entries = logEntries else { return 0 }
        return entries.filter { $0.type == .saved }.count
    }
    
    var cleanDays: Int {
        guard let entries = logEntries else { return daysSinceStart }
        let relapseDays = entries.filter { $0.type == .relapse }.count
        return max(0, daysSinceStart - relapseDays)
    }
    
    /// Current streak of days without relapse
    var currentStreak: Int {
        guard let entries = logEntries else { return daysSinceStart }
        let sortedRelapses = entries
            .filter { $0.type == .relapse }
            .sorted { $0.timestamp > $1.timestamp }
        
        guard let lastRelapse = sortedRelapses.first else {
            // No relapses — streak from start
            return daysSinceStart
        }
        
        let calendar = Calendar.current
        let startOfRelapse = calendar.startOfDay(for: lastRelapse.timestamp)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfRelapse, to: startOfToday)
        // Relapse today = 0 days streak, relapse yesterday = 1 day streak, etc.
        return max(0, components.day ?? 0)
    }
}

// MARK: - Habit Presets

extension Habit {
    static var presets: [(name: String, icon: String, avgCost: Double, frequency: HabitFrequency, color: String)] {
        [
            ("Smoking", "smoke.fill", 300.0, .daily, "#FF6B6B"),
            ("Alcohol", "wineglass.fill", 1500.0, .weekly, "#9B59B6"),
            ("Fast food", "fork.knife", 500.0, .daily, "#F39C12"),
            ("Coffee shop", "cup.and.saucer.fill", 250.0, .daily, "#8B4513"),
            ("Gambling", "dice.fill", 3000.0, .weekly, "#E74C3C"),
            ("Sugary drinks", "waterbottle.fill", 150.0, .daily, "#3498DB"),
            ("Subscriptions", "tv.fill", 500.0, .monthly, "#1ABC9C"),
            ("Impulse purchases", "cart.fill", 2000.0, .weekly, "#E91E63"),
            ("Snacks", "carrot.fill", 200.0, .daily, "#FF9800"),
            ("Energy drinks", "bolt.fill", 200.0, .daily, "#00BCD4")
        ]
    }
}
