import Combine
import FirebaseRemoteConfig
import Foundation

class PreferenceLoader: ObservableObject {
    static let shared = PreferenceLoader()

    private var backend = RemoteConfig.remoteConfig()
    private let paramKey = "url_9"

    private init() {
        let opts = RemoteConfigSettings()
        opts.minimumFetchInterval = 0
        backend.configSettings = opts
        backend.setDefaults(fromPlist: "RemoteConfigDefaults")
    }

    func loadPreferences() async -> (url: String?, state: PreferenceLoadState) {
        do {
            let status = try await backend.fetchAndActivate()

            switch status {
            case .successFetchedFromRemote, .successUsingPreFetchedData:
                let value = backend.configValue(forKey: paramKey).stringValue ?? ""
                return (value.isEmpty ? nil : value, .success)

            case .error:
                let err = NSError(
                    domain: "AppConfig",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Configuration retrieval failed"]
                )
                return (nil, .error(err))

            @unknown default:
                let err = NSError(
                    domain: "AppConfig",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown configuration state"]
                )
                return (nil, .error(err))
            }

        } catch let error as NSError {
            if error.domain == RemoteConfigErrorDomain && error.code == RemoteConfigError.throttled.rawValue {
                let cached = backend.configValue(forKey: paramKey).stringValue
                let url = cached.isEmpty == false ? cached : nil
                return (url, .throttled)
            }
            return (nil, .error(error))
        }
    }
}
