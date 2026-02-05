import Foundation
import SwiftData

enum Currency: String, Codable, CaseIterable {
    case rub = "RUB"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cny = "CNY"
    case inr = "INR"
    case brl = "BRL"
    case cad = "CAD"
    case aud = "AUD"
    
    var symbol: String {
        switch self {
        case .rub: return "₽"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cny: return "¥"
        case .inr: return "₹"
        case .brl: return "R$"
        case .cad: return "C$"
        case .aud: return "A$"
        }
    }
    
    var displayName: String {
        switch self {
        case .rub: return "Russian Ruble"
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cny: return "Chinese Yuan"
        case .inr: return "Indian Rupee"
        case .brl: return "Brazilian Real"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        }
    }
}

@Model
final class UserSettings {
    var id: UUID
    var userName: String
    var currency: Currency
    var annualInterestRate: Double // As percentage, e.g., 10 for 10%
    var compoundingFrequency: Int // Times per year (12 = monthly, 365 = daily)
    var hapticFeedbackEnabled: Bool
    var createdAt: Date
    var lastUpdated: Date
    
    init(
        userName: String = "User",
        currency: Currency = .rub,
        annualInterestRate: Double = 10.0,
        compoundingFrequency: Int = 12,
        hapticFeedbackEnabled: Bool = true
    ) {
        self.id = UUID()
        self.userName = userName
        self.currency = currency
        self.annualInterestRate = annualInterestRate
        self.compoundingFrequency = compoundingFrequency
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency.symbol)\(Int(amount))"
    }
    
    func formatCompactCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return "\(String(format: "%.1f", amount / 1_000_000))M \(currency.symbol)"
        } else if amount >= 1_000 {
            return "\(String(format: "%.1f", amount / 1_000))K \(currency.symbol)"
        } else {
            return formatCurrency(amount)
        }
    }
}

// MARK: - Default Settings

extension UserSettings {
    static var defaultSettings: UserSettings {
        UserSettings()
    }
}
