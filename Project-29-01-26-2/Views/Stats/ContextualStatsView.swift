import SwiftUI
import SwiftData

struct ContextualStatsView: View {
    @Query private var habits: [Habit]
    @Query private var settings: [UserSettings]
    
    @State private var animateStats = false
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings.defaultSettings
    }
    
    private var totalSaved: Double {
        habits.filter { $0.isActive }.reduce(0) { $0 + $1.totalSaved }
    }
    
    private var stats: [ContextualStats.StatItem] {
        ContextualStats.generate(totalSavings: totalSaved, currency: userSettings.currency)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Motivational Quote
                    motivationalQuoteSection
                    
                    // Stats Grid
                    statsGridSection
                    
                    // Fun Facts
                    funFactsSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Your Impact")
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateStats = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animateStats ? 1 : 0.5)
                .opacity(animateStats ? 1 : 0)
            
            Text("With your savings")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(userSettings.formatCurrency(totalSaved))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
            Text("You could buy...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.1),
                            Color.green.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    // MARK: - Motivational Quote
    
    private var motivationalQuoteSection: some View {
        let quotes = [
            ("A penny saved is a penny earned.", "Benjamin Franklin"),
            ("Small daily improvements lead to stunning results.", "Robin Sharma"),
            ("The secret of your future is hidden in your daily routine.", "Mike Murdock"),
            ("It's not how much you earn, it's how much you keep.", "Robert Kiyosaki")
        ]
        
        let randomQuote = quotes.randomElement() ?? quotes[0]
        
        return VStack(spacing: 8) {
            Text("\"\(randomQuote.0)\"")
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.center)
            
            Text("— \(randomQuote.1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Stats Grid
    
    private var statsGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                StatCard(stat: stat)
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                        value: animateStats
                    )
            }
        }
    }
    
    // MARK: - Fun Facts
    
    private var funFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fun facts")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                FunFactCard(
                    icon: "globe.americas.fill",
                    fact: "Your savings could plant \(Int(totalSaved / 200)) trees, offsetting \(Int(totalSaved * 10)) kg of CO2!",
                    color: .green
                )
                
                FunFactCard(
                    icon: "heart.fill",
                    fact: "You may have added \(Int(totalSaved / 100)) hours to your life by quitting bad habits!",
                    color: .red
                )
                
                FunFactCard(
                    icon: "clock.fill",
                    fact: "You saved roughly \(Int(totalSaved / 50)) minutes of time not spent on bad habits!",
                    color: .blue
                )
                
                FunFactCard(
                    icon: "chart.bar.fill",
                    fact: "You're in the top 10% of people who stick to their goals!",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let stat: ContextualStats.StatItem
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: stat.icon)
                .font(.title)
                .foregroundColor(Color(hex: stat.color))
            
            Text(stat.value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Fun Fact Card

struct FunFactCard: View {
    let icon: String
    let fact: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(fact)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    ContextualStatsView()
        .modelContainer(for: [Habit.self, LogEntry.self, Achievement.self, UserSettings.self], inMemory: true)
}
