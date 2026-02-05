import Foundation
import SwiftData

enum LogEntryType: String, Codable {
    case saved = "Saved"
    case relapse = "Relapse"
    
    /// Localized display name for UI
    var displayName: String {
        switch self {
        case .saved: return "Clean day"
        case .relapse: return "Relapse"
        }
    }
}

@Model
final class LogEntry {
    var id: UUID
    var type: LogEntryType
    var amount: Double
    var timestamp: Date
    var note: String?
    
    var habit: Habit?
    
    init(
        type: LogEntryType,
        amount: Double,
        timestamp: Date = Date(),
        note: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.amount = amount
        self.timestamp = timestamp
        self.note = note
    }
}

extension LogEntry {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: timestamp)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: timestamp)
    }
}
