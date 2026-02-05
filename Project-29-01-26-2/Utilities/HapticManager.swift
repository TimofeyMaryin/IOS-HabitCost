import SwiftUI

/// Haptic Feedback Manager for providing tactile feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func lightImpact() {
        impact(.light)
    }
    
    func mediumImpact() {
        impact(.medium)
    }
    
    func heavyImpact() {
        impact(.heavy)
    }
    
    func softImpact() {
        impact(.soft)
    }
    
    func rigidImpact() {
        impact(.rigid)
    }
    
    // MARK: - Notification Feedback
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func success() {
        notification(.success)
    }
    
    func warning() {
        notification(.warning)
    }
    
    func error() {
        notification(.error)
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    func achievementUnlocked() {
        // Triple success pattern
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.success()
        }
    }
    
    func logSaved() {
        success()
    }
    
    func logRelapse() {
        warning()
    }
    
    func buttonTap() {
        lightImpact()
    }
    
    func sliderChanged() {
        selection()
    }
}

// MARK: - SwiftUI Modifier

struct HapticModifier: ViewModifier {
    let type: HapticType
    
    enum HapticType {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
        case selection
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                switch type {
                case .light:
                    HapticManager.shared.lightImpact()
                case .medium:
                    HapticManager.shared.mediumImpact()
                case .heavy:
                    HapticManager.shared.heavyImpact()
                case .success:
                    HapticManager.shared.success()
                case .warning:
                    HapticManager.shared.warning()
                case .error:
                    HapticManager.shared.error()
                case .selection:
                    HapticManager.shared.selection()
                }
            }
    }
}

extension View {
    func hapticFeedback(_ type: HapticModifier.HapticType) -> some View {
        modifier(HapticModifier(type: type))
    }
}
