import SwiftUI

extension Color {
    // MARK: - Initialize from Hex String
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - App Theme Colors
    
    static let appGreen = Color.green
    static let appRed = Color.red
    static let appOrange = Color.orange
    static let appBlue = Color.blue
    static let appPurple = Color.purple
    
    // MARK: - Semantic Colors
    
    static let savingsColor = Color.green
    static let relapseColor = Color.red
    static let progressColor = Color.blue
    static let goalColor = Color.purple
    static let investmentColor = Color.orange
    
    // MARK: - Card Background
    
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let cardBackgroundElevated = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Gradient Presets
    
    static let savingsGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let investmentGradient = LinearGradient(
        colors: [Color.orange, Color.yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let streakGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let relapseGradient = LinearGradient(
        colors: [Color.red, Color.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static let dashboardCard = LinearGradient(
        colors: [
            Color(UIColor.systemBackground),
            Color(UIColor.secondarySystemBackground)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
