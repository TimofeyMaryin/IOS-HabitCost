import SwiftUI
import WebKit

struct EmbeddedWebView: UIViewRepresentable {
    let targetUrl: String

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard
            let encoded = targetUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: encoded)
        else { return }

        if view.url != url {
            let request = URLRequest(url: url)
            view.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ view: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {}

        func webView(_ view: WKWebView, didFinish navigation: WKNavigation!) {}

        func webView(_ view: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {}
    }
}
