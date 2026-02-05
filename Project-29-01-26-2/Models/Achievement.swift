import Foundation
import SwiftData

enum AchievementCategory: String, Codable, CaseIterable {
    case entertainment = "Entertainment"
    case technology = "Technology"
    case travel = "Travel"
    case lifestyle = "Lifestyle"
    case milestone = "Milestone"
    
    var iconName: String {
        switch self {
        case .entertainment: return "film.fill"
        case .technology: return "desktopcomputer"
        case .travel: return "airplane"
        case .lifestyle: return "heart.fill"
        case .milestone: return "star.fill"
        }
    }
    
    /// Localized display name for UI
    var displayName: String {
        switch self {
        case .entertainment: return "Entertainment"
        case .technology: return "Technology"
        case .travel: return "Travel"
        case .lifestyle: return "Lifestyle"
        case .milestone: return "Milestones"
        }
    }
}

@Model
final class Achievement {
    var id: UUID
    var title: String
    var descriptionText: String
    var targetAmount: Double
    var iconName: String
    var category: AchievementCategory
    var isUnlocked: Bool
    var unlockedDate: Date?
    var isPinned: Bool
    var sortOrder: Int
    
    init(
        title: String,
        descriptionText: String = "",
        targetAmount: Double,
        iconName: String = "star.fill",
        category: AchievementCategory = .milestone,
        isUnlocked: Bool = false,
        isPinned: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = descriptionText
        self.targetAmount = targetAmount
        self.iconName = iconName
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedDate = nil
        self.isPinned = isPinned
        self.sortOrder = sortOrder
    }
    
    func progress(currentSavings: Double) -> Double {
        guard targetAmount > 0 else { return 1.0 }
        return min(1.0, currentSavings / targetAmount)
    }
    
    func checkAndUnlock(currentSavings: Double) -> Bool {
        if !isUnlocked && currentSavings >= targetAmount {
            isUnlocked = true
            unlockedDate = Date()
            return true
        }
        return false
    }
}

// MARK: - Default Achievements

extension Achievement {
    static var defaults: [Achievement] {
        [
            // Entertainment
            Achievement(title: "Movie ticket", descriptionText: "A night at the cinema", targetAmount: 500, iconName: "ticket.fill", category: .entertainment, sortOrder: 1),
            Achievement(title: "Concert", descriptionText: "Live music", targetAmount: 3000, iconName: "music.note", category: .entertainment, sortOrder: 2),
            Achievement(title: "Year of streaming", descriptionText: "A year of streaming service", targetAmount: 4000, iconName: "play.tv.fill", category: .entertainment, sortOrder: 3),
            Achievement(title: "Gaming console", descriptionText: "Next-level entertainment", targetAmount: 40000, iconName: "gamecontroller.fill", category: .entertainment, sortOrder: 4),
            
            // Technology
            Achievement(title: "Wireless earbuds", descriptionText: "Freedom without wires", targetAmount: 10000, iconName: "airpodspro", category: .technology, sortOrder: 5),
            Achievement(title: "Smartwatch", descriptionText: "Track your healthy lifestyle", targetAmount: 30000, iconName: "applewatch", category: .technology, sortOrder: 6),
            Achievement(title: "New iPhone", descriptionText: "The best upgrade", targetAmount: 80000, iconName: "iphone", category: .technology, sortOrder: 7),
            Achievement(title: "MacBook", descriptionText: "Power for creativity", targetAmount: 120000, iconName: "laptopcomputer", category: .technology, sortOrder: 8),
            
            // Travel
            Achievement(title: "Weekend getaway", descriptionText: "Short break", targetAmount: 15000, iconName: "car.fill", category: .travel, sortOrder: 9),
            Achievement(title: "Flight ticket", descriptionText: "To the skies!", targetAmount: 25000, iconName: "airplane", category: .travel, sortOrder: 10),
            Achievement(title: "Beach trip", descriptionText: "Sun and sand await", targetAmount: 80000, iconName: "sun.max.fill", category: .travel, sortOrder: 11),
            Achievement(title: "Europe vacation", descriptionText: "Explore the old continent", targetAmount: 200000, iconName: "globe.europe.africa.fill", category: .travel, sortOrder: 12),
            
            // Lifestyle
            Achievement(title: "Restaurant dinner", descriptionText: "Treat yourself", targetAmount: 5000, iconName: "fork.knife", category: .lifestyle, sortOrder: 13),
            Achievement(title: "Gym membership", descriptionText: "Investment in health", targetAmount: 20000, iconName: "figure.run", category: .lifestyle, sortOrder: 14),
            Achievement(title: "New wardrobe", descriptionText: "Look and feel great", targetAmount: 30000, iconName: "tshirt.fill", category: .lifestyle, sortOrder: 15),
            Achievement(title: "Quality watch", descriptionText: "Timeless value", targetAmount: 100000, iconName: "clock.fill", category: .lifestyle, sortOrder: 16),
            
            // Milestones
            Achievement(title: "First 1,000 saved", descriptionText: "The journey begins!", targetAmount: 1000, iconName: "leaf.fill", category: .milestone, sortOrder: 17),
            Achievement(title: "First 5,000 saved", descriptionText: "Already progress!", targetAmount: 5000, iconName: "star.fill", category: .milestone, sortOrder: 18),
            Achievement(title: "First 10,000 saved", descriptionText: "Five figures!", targetAmount: 10000, iconName: "star.circle.fill", category: .milestone, sortOrder: 19),
            Achievement(title: "First 50,000 saved", descriptionText: "Serious savings", targetAmount: 50000, iconName: "trophy.fill", category: .milestone, sortOrder: 20),
            Achievement(title: "First 100,000 saved", descriptionText: "Six figures!", targetAmount: 100000, iconName: "crown.fill", category: .milestone, sortOrder: 21),
            Achievement(title: "First 500,000 saved", descriptionText: "You're unstoppable!", targetAmount: 500000, iconName: "sparkles", category: .milestone, sortOrder: 22),
        ]
    }
}
