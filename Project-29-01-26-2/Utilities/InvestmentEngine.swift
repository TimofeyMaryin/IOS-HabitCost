import Foundation

/// Investment Engine using Compound Interest Formula: A = P × (1 + r/n)^(nt)
/// Where:
/// - A = Final amount
/// - P = Principal (initial investment)
/// - r = Annual interest rate (decimal)
/// - n = Compounding frequency per year
/// - t = Time in years
struct InvestmentEngine {
    
    // MARK: - Core Calculations
    
    /// Calculate future value with compound interest
    /// - Parameters:
    ///   - principal: Initial amount invested
    ///   - annualRate: Annual interest rate as percentage (e.g., 10 for 10%)
    ///   - compoundingFrequency: Times interest is compounded per year
    ///   - years: Number of years
    /// - Returns: Future value of the investment
    static func futureValue(
        principal: Double,
        annualRate: Double,
        compoundingFrequency: Int = 12,
        years: Double
    ) -> Double {
        guard principal > 0, years > 0 else { return principal }
        
        let r = annualRate / 100.0 // Convert percentage to decimal
        let n = Double(compoundingFrequency)
        let t = years
        
        // A = P × (1 + r/n)^(nt)
        let amount = principal * pow(1 + r/n, n * t)
        return amount
    }
    
    /// Calculate future value with regular contributions (like saving daily/monthly)
    /// - Parameters:
    ///   - principal: Initial amount
    ///   - regularContribution: Amount added each period
    ///   - contributionFrequency: Times contributions are made per year
    ///   - annualRate: Annual interest rate as percentage
    ///   - compoundingFrequency: Times interest is compounded per year
    ///   - years: Number of years
    /// - Returns: Future value including all contributions with compound interest
    static func futureValueWithContributions(
        principal: Double,
        regularContribution: Double,
        contributionFrequency: Int = 365, // Daily savings
        annualRate: Double,
        compoundingFrequency: Int = 12,
        years: Double
    ) -> Double {
        guard years > 0 else { return principal }
        
        let r = annualRate / 100.0
        let n = Double(compoundingFrequency)
        let t = years
        
        // Future value of principal
        let principalFV = principal * pow(1 + r/n, n * t)
        
        // Future value of annuity (regular contributions)
        // Using formula: PMT × [((1 + r/n)^(nt) - 1) / (r/n)]
        let periodicRate = r / n
        let totalPeriods = n * t
        
        // Convert contribution to per-compounding-period amount
        let contributionsPerCompoundPeriod = Double(contributionFrequency) / n
        let contributionPerPeriod = regularContribution * contributionsPerCompoundPeriod
        
        var contributionsFV: Double = 0
        if periodicRate > 0 {
            contributionsFV = contributionPerPeriod * ((pow(1 + periodicRate, totalPeriods) - 1) / periodicRate)
        } else {
            contributionsFV = contributionPerPeriod * totalPeriods
        }
        
        return principalFV + contributionsFV
    }
    
    /// Generate projection data points for charting
    static func generateProjection(
        currentSavings: Double,
        dailySavingsRate: Double,
        annualRate: Double,
        years: Int,
        dataPointsCount: Int = 20
    ) -> [ProjectionDataPoint] {
        var dataPoints: [ProjectionDataPoint] = []
        
        let step = max(1, years / dataPointsCount)
        
        for year in stride(from: 0, through: years, by: step) {
            let yearDouble = Double(year)
            
            // Calculate total contributions up to this point
            let totalContributions = currentSavings + (dailySavingsRate * 365 * yearDouble)
            
            // Calculate with compound interest
            let withInterest = futureValueWithContributions(
                principal: currentSavings,
                regularContribution: dailySavingsRate,
                contributionFrequency: 365,
                annualRate: annualRate,
                compoundingFrequency: 12,
                years: yearDouble
            )
            
            let interestEarned = withInterest - totalContributions
            
            dataPoints.append(ProjectionDataPoint(
                year: year,
                savings: totalContributions,
                withInterest: withInterest,
                interestEarned: interestEarned
            ))
        }
        
        // Ensure we have the final year
        if dataPoints.last?.year != years {
            let yearDouble = Double(years)
            let totalContributions = currentSavings + (dailySavingsRate * 365 * yearDouble)
            let withInterest = futureValueWithContributions(
                principal: currentSavings,
                regularContribution: dailySavingsRate,
                contributionFrequency: 365,
                annualRate: annualRate,
                compoundingFrequency: 12,
                years: yearDouble
            )
            
            dataPoints.append(ProjectionDataPoint(
                year: years,
                savings: totalContributions,
                withInterest: withInterest,
                interestEarned: withInterest - totalContributions
            ))
        }
        
        return dataPoints
    }
    
    /// Calculate interest earned only
    static func interestEarned(
        principal: Double,
        annualRate: Double,
        compoundingFrequency: Int = 12,
        years: Double
    ) -> Double {
        let fv = futureValue(
            principal: principal,
            annualRate: annualRate,
            compoundingFrequency: compoundingFrequency,
            years: years
        )
        return fv - principal
    }
    
    /// Calculate how long until a goal is reached
    static func yearsToGoal(
        currentSavings: Double,
        dailySavingsRate: Double,
        goalAmount: Double,
        annualRate: Double
    ) -> Double {
        guard goalAmount > currentSavings else { return 0 }
        guard dailySavingsRate > 0 else { return .infinity }
        
        // Binary search for the year when goal is reached
        var low: Double = 0
        var high: Double = 100 // Max 100 years
        
        while high - low > 0.01 {
            let mid = (low + high) / 2
            let fv = futureValueWithContributions(
                principal: currentSavings,
                regularContribution: dailySavingsRate,
                contributionFrequency: 365,
                annualRate: annualRate,
                compoundingFrequency: 12,
                years: mid
            )
            
            if fv >= goalAmount {
                high = mid
            } else {
                low = mid
            }
        }
        
        return high
    }
    
    /// Calculate goal achievement date
    static func goalAchievementDate(
        currentSavings: Double,
        dailySavingsRate: Double,
        goalAmount: Double,
        annualRate: Double
    ) -> Date? {
        let years = yearsToGoal(
            currentSavings: currentSavings,
            dailySavingsRate: dailySavingsRate,
            goalAmount: goalAmount,
            annualRate: annualRate
        )
        
        guard years.isFinite && years < 100 else { return nil }
        
        let days = Int(years * 365)
        return Calendar.current.date(byAdding: .day, value: days, to: Date())
    }
}

// MARK: - Data Point for Charts

struct ProjectionDataPoint: Identifiable {
    let id = UUID()
    let year: Int
    let savings: Double
    let withInterest: Double
    let interestEarned: Double
}

// MARK: - Contextual Stats Generator

struct ContextualStats {
    
    struct StatItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let value: String
        let color: String
    }
    
    /// Returns approximate prices for common items based on currency
    /// Base prices are in the currency's typical local value
    private static func getPrices(for currency: Currency) -> (
        lunch: Double, coffee: Double, pizza: Double,
        gas: Double, taxi: Double, bus: Double,
        movie: Double, streaming: Double, book: Double,
        gym: Double, yoga: Double, app: Double
    ) {
        switch currency {
        case .rub:
            return (500, 250, 800, 55, 400, 60, 500, 500, 700, 500, 1000, 300)
        case .usd:
            return (15, 5, 20, 3.5, 15, 2.5, 15, 15, 20, 15, 25, 5)
        case .eur:
            return (14, 4.5, 18, 1.8, 12, 2, 12, 13, 18, 12, 22, 5)
        case .gbp:
            return (12, 4, 15, 1.5, 10, 1.8, 12, 11, 15, 10, 20, 4)
        case .jpy:
            return (1200, 500, 2000, 170, 1500, 200, 1800, 1500, 1500, 1000, 2500, 500)
        case .cny:
            return (50, 25, 80, 8, 30, 3, 50, 40, 50, 50, 100, 25)
        case .inr:
            return (300, 150, 500, 100, 200, 30, 300, 200, 400, 300, 500, 100)
        case .brl:
            return (50, 15, 60, 6, 25, 5, 40, 45, 60, 50, 80, 20)
        case .cad:
            return (18, 6, 25, 1.8, 18, 3.5, 16, 17, 25, 18, 30, 6)
        case .aud:
            return (20, 6, 25, 2, 20, 4, 20, 18, 30, 20, 35, 7)
        }
    }
    
    static func generate(totalSavings: Double, currency: Currency) -> [StatItem] {
        var stats: [StatItem] = []
        
        let prices = getPrices(for: currency)
        
        // Food
        stats.append(StatItem(
            icon: "fork.knife",
            title: "Business lunches",
            value: "\(Int(totalSavings / prices.lunch))",
            color: "#FF6B6B"
        ))
        
        stats.append(StatItem(
            icon: "cup.and.saucer.fill",
            title: "Cups of coffee",
            value: "\(Int(totalSavings / prices.coffee))",
            color: "#8B4513"
        ))
        
        stats.append(StatItem(
            icon: "flame.fill",
            title: "Pizzas",
            value: "\(Int(totalSavings / prices.pizza))",
            color: "#E74C3C"
        ))
        
        // Transport
        stats.append(StatItem(
            icon: "fuelpump.fill",
            title: "Liters of gas",
            value: "\(Int(totalSavings / prices.gas)) L",
            color: "#3498DB"
        ))
        
        stats.append(StatItem(
            icon: "car.fill",
            title: "Taxi rides",
            value: "\(Int(totalSavings / prices.taxi))",
            color: "#1ABC9C"
        ))
        
        stats.append(StatItem(
            icon: "bus.fill",
            title: "Bus tickets",
            value: "\(Int(totalSavings / prices.bus))",
            color: "#9B59B6"
        ))
        
        // Entertainment
        stats.append(StatItem(
            icon: "ticket.fill",
            title: "Movie tickets",
            value: "\(Int(totalSavings / prices.movie))",
            color: "#E91E63"
        ))
        
        stats.append(StatItem(
            icon: "play.tv.fill",
            title: "Months of streaming",
            value: "\(Int(totalSavings / prices.streaming)) mo",
            color: "#F44336"
        ))
        
        stats.append(StatItem(
            icon: "book.fill",
            title: "Books",
            value: "\(Int(totalSavings / prices.book))",
            color: "#795548"
        ))
        
        // Health & fitness
        stats.append(StatItem(
            icon: "figure.run",
            title: "Gym drop-ins",
            value: "\(Int(totalSavings / prices.gym))",
            color: "#4CAF50"
        ))
        
        stats.append(StatItem(
            icon: "figure.yoga",
            title: "Yoga classes",
            value: "\(Int(totalSavings / prices.yoga))",
            color: "#00BCD4"
        ))
        
        // Tech
        stats.append(StatItem(
            icon: "app.badge.fill",
            title: "Paid apps",
            value: "\(Int(totalSavings / prices.app))",
            color: "#2196F3"
        ))
        
        return stats
    }
}
