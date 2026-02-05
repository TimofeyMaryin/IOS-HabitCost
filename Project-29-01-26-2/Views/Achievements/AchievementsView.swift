import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Achievement.sortOrder) private var achievements: [Achievement]
    @Query private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var selectedCategory: AchievementCategory?
    @State private var showingAddAchievement = false
    @State private var newlyUnlocked: Achievement?
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var totalSaved: Double {
        habits.filter { $0.isActive }.reduce(0) { $0 + $1.totalSaved }
    }
    
    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Summary
                    progressSummarySection
                    
                    // Category Filter
                    categoryFilterSection
                    
                    // Achievement Grid
                    achievementGridSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Goal Tree")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAchievement = true
                        HapticManager.shared.buttonTap()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAchievement) {
                AddAchievementView()
            }
            .alert("Achievement unlocked!", isPresented: .init(
                get: { newlyUnlocked != nil },
                set: { if !$0 { newlyUnlocked = nil } }
            )) {
                Button("Great!") {
                    newlyUnlocked = nil
                }
            } message: {
                if let achievement = newlyUnlocked {
                    Text("Congratulations! You unlocked '\(achievement.title)' worth \(userSettings.formatCurrency(achievement.targetAmount))!")
                }
            }
            .onAppear {
                initializeDefaultsIfNeeded()
                checkForUnlocks()
            }
        }
    }
    
    // MARK: - Progress Summary
    
    private var progressSummarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Unlocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("/")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(achievements.count)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Overall Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemBackground))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * overallProgress)
                    }
                }
                .frame(height: 12)
                
                Text("\(Int(overallProgress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Current savings: \(userSettings.formatCurrency(totalSaved))")
                .font(.subheadline)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var overallProgress: Double {
        guard !achievements.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(achievements.count)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    color: .blue
                ) {
                    selectedCategory = nil
                    HapticManager.shared.selection()
                }
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.displayName,
                        icon: category.iconName,
                        isSelected: selectedCategory == category,
                        color: colorForCategory(category)
                    ) {
                        selectedCategory = category
                        HapticManager.shared.selection()
                    }
                }
            }
        }
    }
    
    // MARK: - Achievement Grid
    
    private var achievementGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(
                    achievement: achievement,
                    currentSavings: totalSaved,
                    settings: userSettings
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func colorForCategory(_ category: AchievementCategory) -> Color {
        switch category {
        case .entertainment: return .purple
        case .technology: return .blue
        case .travel: return .orange
        case .lifestyle: return .pink
        case .milestone: return .yellow
        }
    }
    
    private func initializeDefaultsIfNeeded() {
        if achievements.isEmpty {
            Achievement.defaults.forEach { achievement in
                modelContext.insert(achievement)
            }
        }
    }
    
    private func checkForUnlocks() {
        for achievement in achievements {
            if achievement.checkAndUnlock(currentSavings: totalSaved) {
                newlyUnlocked = achievement
                HapticManager.shared.achievementUnlocked()
                break // Only show one at a time
            }
        }
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(UIColor.secondarySystemBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let currentSavings: Double
    let settings: UserSettings
    
    private var progress: Double {
        achievement.progress(currentSavings: currentSavings)
    }
    
    private var isUnlocked: Bool {
        achievement.isUnlocked || currentSavings >= achievement.targetAmount
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.green.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title)
                    .foregroundColor(isUnlocked ? .green : .secondary)
            }
            
            // Title
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Target Amount
            Text(settings.formatCurrency(achievement.targetAmount))
                .font(.caption)
                .foregroundColor(isUnlocked ? .green : .secondary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.tertiarySystemBackground))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isUnlocked ? Color.green : Color.blue)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
            
            // Progress Percentage
            Text(isUnlocked ? "Unlocked!" : "\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .green : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUnlocked ? Color.green : Color.clear, lineWidth: 2)
                )
        )
        .opacity(isUnlocked ? 1 : 0.8)
    }
}

// MARK: - Add Achievement View

struct AddAchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var targetAmount: String = ""
    @State private var iconName: String = "star.fill"
    @State private var category: AchievementCategory = .milestone
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetAmount) != nil &&
        Double(targetAmount)! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal name", text: $title)
                    
                    HStack {
                        Text("Target amount")
                        Spacer()
                        TextField("0.00", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(AchievementCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                } header: {
                    Text("Goal details")
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach([
                            "star.fill", "trophy.fill", "crown.fill", "medal.fill",
                            "gift.fill", "heart.fill", "airplane", "car.fill",
                            "house.fill", "iphone", "laptopcomputer", "applewatch",
                            "tshirt.fill", "fork.knife", "ticket.fill", "gamecontroller.fill"
                        ], id: \.self) { icon in
                            Button {
                                iconName = icon
                                HapticManager.shared.selection()
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        iconName == icon ?
                                        Color.blue.opacity(0.2) :
                                        Color(UIColor.tertiarySystemBackground)
                                    )
                                    .foregroundColor(iconName == icon ? .blue : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Icon")
                }
            }
            .navigationTitle("New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAchievement()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveAchievement() {
        guard let amount = Double(targetAmount) else { return }
        
        let achievement = Achievement(
            title: title.trimmingCharacters(in: .whitespaces),
            targetAmount: amount,
            iconName: iconName,
            category: category,
            sortOrder: 100 // Custom goals at end
        )
        
        modelContext.insert(achievement)
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
