import SwiftUI
import SwiftData
import Firebase


// Firebase
// 1845
// IOS-Project-05-12-25
// url_9

@main
struct Project_29_01_26_2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            LogEntry.self,
            Achievement.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        FirebaseApp.configure()
    }
    
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var resolvedPath: String?
    @State private var loadState: PreferenceLoadState = .loading
    @State private var flowState: AppFlowState = .splashScreen
    
    var body: some Scene {
        WindowGroup {
            
            ZStack {
                switch flowState {
                case .splashScreen:
                    SplashScreenView()

                case .mainInterface:
                    ContentView()

                case .webView(let path):
                    if let url = URL(string: path) {
                        EmbeddedWebView(targetUrl: url.absoluteString)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Text("Неверный URL")
                    }

                case .errorMessage(let message):
                    VStack(spacing: 20) {
                        Text("Ошибка")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(message)
                        Button("Повторить") {
                            Task { await fetchConfigurationAndNavigate() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await fetchConfigurationAndNavigate()
            }
            .onChange(of: loadState, initial: true) { _, newValue in
                if case .success = newValue, let path = resolvedPath, !path.isEmpty {
                    Task {
                        await verifyAndNavigate(path: path)
                    }
                }
            }
            
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { flowState = .splashScreen }
        
        let (path, state) = await PreferenceLoader.shared.loadPreferences()
        
        await MainActor.run {
            self.resolvedPath = path
            self.loadState = state
        }
        
        if path == nil || path?.isEmpty == true {
            navigateToMainInterface()
        }
    }
    
    private func navigateToMainInterface() {
        withAnimation {
            flowState = .mainInterface
        }
    }
    
    private func verifyAndNavigate(path: String) async {
        guard let url = URL(string: path) else {
            navigateToMainInterface()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse,
               (200...299).contains(http.statusCode) {
                await MainActor.run {
                    flowState = .webView(path)
                }
            } else {
                navigateToMainInterface()
            }
        } catch {
            navigateToMainInterface()
        }
    }
}
