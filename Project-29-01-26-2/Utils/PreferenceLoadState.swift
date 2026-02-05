import Foundation

enum PreferenceLoadState: Equatable {
    case success
    case error(Error)
    case loading
    case throttled

    static func == (lhs: PreferenceLoadState, rhs: PreferenceLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success),
            (.loading, .loading),
            (.throttled, .throttled):
            return true
        case (.error(let leftError), .error(let rightError)):
            return (leftError as NSError) == (rightError as NSError)
        default:
            return false
        }
    }
}
