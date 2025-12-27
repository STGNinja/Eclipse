import SwiftUI
import WebKit

struct CodeRunnerView: View {
    let code: String
    let language: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Area (within navigation)
                    WebViewContainer(code: code, language: language, isLoading: $isLoading)
                        .ignoresSafeArea(edges: .bottom)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Code Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Trigger reload manually if needed or just re-render
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundStyle(.orange)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let code: String
    let language: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .white // Default to white for web content unless specified
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlSnippet: String
        
        switch language.lowercased() {
        case "html":
            htmlSnippet = code
        case "css":
            htmlSnippet = "<html><head><style>\(code)</style></head><body><p>CSS Preview</p></body></html>"
        case "javascript", "js":
            htmlSnippet = "<html><body><script>\(code)</script><p>Check console or visual output.</p></body></html>"
        default:
            // Attempt to treat as HTML if unknown but runnable
            htmlSnippet = code
        }
        
        // Wrap in basic boilerplate if it's just a fragment
        let fullHTML: String
        if !htmlSnippet.lowercased().contains("<html") {
            fullHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 20px; background-color: #fff; color: #333; }
                </style>
            </head>
            <body>
                \(htmlSnippet)
            </body>
            </html>
            """
        } else {
            fullHTML = htmlSnippet
        }
        
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
