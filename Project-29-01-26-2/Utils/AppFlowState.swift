import Foundation

enum AppFlowState {
    case splashScreen
    case mainInterface
    case webView(String)
    case errorMessage(String)
}
