import SwiftUI
import WebKit

struct LatexMarkdownView: UIViewRepresentable {
    let text: String
    @Binding var dynamicHeight: CGFloat
    var isCodeMode: Bool = false
    var onRunCode: ((String, String) -> Void)? = nil // language, code
    
    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController.add(context.coordinator, name: "heightHandler")
        webConfiguration.userContentController.add(context.coordinator, name: "runHandler")
        
        // Transparent background
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        #if os(iOS)
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false // Let SwiftUI handle scrolling
        #endif
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update the coordinator with the latest text
        context.coordinator.pendingText = text
        
        // If the view is loaded, update content via JS to avoid reload flash
        if context.coordinator.isLoaded {
            context.coordinator.updateContent(in: webView, text: text)
        } else if !context.coordinator.isLoading {
            // Initial load
            context.coordinator.isLoading = true
            let htmlContent = generateHTML(content: text)
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }
        // If loading, we do nothing; didFinish will handle pendingText
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: LatexMarkdownView
        var isLoaded = false
        var isLoading = false
        var pendingText: String = ""
        
        init(_ parent: LatexMarkdownView) {
            self.parent = parent
        }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "heightHandler", let height = message.body as? CGFloat {
                DispatchQueue.main.async {
                    // Use a threshold to avoid infinite layout loops or jitter
                    if abs(self.parent.dynamicHeight - height) > 10 {
                        self.parent.dynamicHeight = height
                    }
                }
            } else if message.name == "runHandler", let body = message.body as? [String: String],
                      let lang = body["lang"], let code = body["code"] {
                DispatchQueue.main.async {
                    self.parent.onRunCode?(lang, code)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            isLoading = false
            // Check if text changed while loading
            updateContent(in: webView, text: pendingText)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
        
        func updateContent(in webView: WKWebView, text: String) {
            guard let data = text.data(using: .utf8) else { return }
            let base64 = data.base64EncodedString()
            // Call JS function with base64 string
            let script = "updateContent('\(base64)');"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    // MARK: - HTML Generation
    
    private func generateHTML(content: String) -> String {
        let css = #"""
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600&family=Source+Serif+Pro:wght@400;600&display=swap');
            
            body {
                background-color: transparent;
                color: rgba(255, 255, 255, 0.9);
                font-family: 'Source Serif Pro', serif;
                font-size: 18px;
                line-height: 1.6;
                margin: 0;
                padding: 0; 
                padding-bottom: 4px; 
            }
            
            .lucide-icon {
                width: 1.1em;
                height: 1.1em;
                vertical-align: middle;
                margin-top: -2px;
                display: inline-block;
                color: #FFA500;
                filter: drop-shadow(0 0 5px rgba(255, 165, 0, 0.4));
            }
            
            p { margin-bottom: 14px; margin-top: 0; }
            p:last-child { margin-bottom: 0px; }
            h1, h2, h3, h4 { 
                font-family: 'Outfit', sans-serif;
                color: #fff;
                margin-top: 24px;
                margin-bottom: 12px;
                font-weight: 600;
            }
            h1 { font-size: 24px; border-bottom: 1px solid rgba(255,165,0,0.3); padding-bottom: 8px; }
            h2 { font-size: 20px; }
            h3 { font-size: 18px; }
            
            a { color: #FFA500; text-decoration: none; }
            strong { font-weight: 600; color: #fff; }
            em { color: rgba(255,255,255,0.8); }
            
            /* Rich Link Card Styling with Enhanced Glass */
            .link-card {
                background: rgba(255, 255, 255, 0.08);
                border: 1px solid rgba(255, 255, 255, 0.15);
                border-radius: 20px;
                padding: 14px 18px;
                margin: 18px 0;
                display: flex;
                align-items: center;
                gap: 16px;
                text-decoration: none !important;
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                backdrop-filter: blur(25px) saturate(1.8);
                -webkit-backdrop-filter: blur(25px) saturate(1.8);
                box-shadow: 0 4px 24px rgba(0, 0, 0, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.1);
                position: relative;
                overflow: hidden;
            }
            .link-card::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 1px;
                background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
            }
            .link-card:active {
                background: rgba(255, 255, 255, 0.15);
                transform: scale(0.97);
                box-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
            }
            .link-icon {
                width: 44px;
                height: 44px;
                background: linear-gradient(135deg, #FFA500, #FF4500);
                border-radius: 12px;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-shrink: 0;
            }
            .link-content {
                flex-grow: 1;
                overflow: hidden;
            }
            .link-title {
                color: #fff;
                font-weight: 600;
                font-size: 16px;
                margin-bottom: 2px;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
            }
            .link-url {
                color: rgba(255, 255, 255, 0.4);
                font-size: 13px;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
            }

            /* Mermaid Diagram Styling with Glass */
            .mermaid {
                background: rgba(255, 255, 255, 0.04);
                backdrop-filter: blur(20px) saturate(1.5);
                -webkit-backdrop-filter: blur(20px) saturate(1.5);
                border-radius: 20px;
                padding: 24px;
                margin: 20px 0;
                border: 1px solid rgba(255, 255, 255, 0.12);
                display: flex;
                justify-content: center;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.05);
            }
            .mermaid svg {
                max-width: 100% !important;
                height: auto !important;
                filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.3));
            }
            
            /* Image Gallery Styling */
            .image-gallery {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                gap: 12px;
                margin: 20px 0;
            }
            .image-gallery img {
                width: 100%;
                height: 200px;
                object-fit: cover;
                border-radius: 12px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
                transition: transform 0.2s;
            }
            .image-gallery img:active {
                transform: scale(0.95);
            }
            img {
                max-width: 100%;
                border-radius: 12px;
                margin: 16px 0;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            }
            
            /* Progress Bar Styling - Use sparingly for timelines/metrics */
            .progress-bar {
                background: rgba(255, 255, 255, 0.1);
                border-radius: 8px;
                height: 12px;
                overflow: hidden;
                margin: 12px 0;
                position: relative;
            }
            .progress-bar-fill {
                background: linear-gradient(90deg, #FFA500, #FF4500);
                height: 100%;
                transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
                border-radius: 8px;
                box-shadow: 0 0 10px rgba(255, 165, 0, 0.5);
            }
            .progress-label {
                font-size: 13px;
                color: rgba(255, 255, 255, 0.6);
                margin-bottom: 4px;
                font-family: 'Outfit', sans-serif;
            }
            
            /* Math styling - boxed answers */
            .MathJax {
                color: rgba(255, 255, 255, 0.95) !important;
            }
            mjx-container[display="true"] {
                margin: 20px 0 !important;
            }
            
            /* Math step container with glass effect */
            .math-step {
                background: rgba(255, 255, 255, 0.05);
                backdrop-filter: blur(20px) saturate(1.8);
                -webkit-backdrop-filter: blur(20px) saturate(1.8);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-left: 3px solid rgba(255, 165, 0, 0.6);
                border-radius: 16px;
                padding: 18px 22px;
                margin: 18px 0;
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
            }
            .math-step:hover {
                background: rgba(255, 255, 255, 0.08);
                border-left-color: rgba(255, 165, 0, 1);
                transform: translateX(4px);
                box-shadow: 0 12px 40px rgba(255, 165, 0, 0.15);
            }
            .math-step-title {
                font-family: 'Outfit', sans-serif;
                font-weight: 600;
                color: #FFA500;
                font-size: 15px;
                margin-bottom: 10px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                text-shadow: 0 2px 8px rgba(255, 165, 0, 0.3);
            }
            .math-step-content {
                color: rgba(255, 255, 255, 0.95);
                line-height: 1.9;
            }
            
            /* Final answer highlight with glass effect */
            .final-answer {
                background: linear-gradient(135deg, rgba(255, 165, 0, 0.2), rgba(255, 69, 0, 0.2));
                backdrop-filter: blur(25px) saturate(2);
                -webkit-backdrop-filter: blur(25px) saturate(2);
                border: 2px solid rgba(255, 165, 0, 0.5);
                border-radius: 20px;
                padding: 24px;
                margin: 28px 0;
                text-align: center;
                box-shadow: 0 8px 32px rgba(255, 165, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.1);
                position: relative;
                overflow: hidden;
            }
            .final-answer::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 1px;
                background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
            }
            .final-answer-label {
                font-family: 'Outfit', sans-serif;
                font-weight: 600;
                color: #FFA500;
                font-size: 14px;
                text-transform: uppercase;
                letter-spacing: 1.5px;
                margin-bottom: 14px;
                text-shadow: 0 2px 12px rgba(255, 165, 0, 0.4);
            }
            
            /* Inline code for math variables */
            code {
                background: rgba(255, 165, 0, 0.1);
                color: #FFB84D;
                padding: 2px 6px;
                border-radius: 4px;
                font-family: 'SF Mono', 'Menlo', monospace;
                font-size: 0.9em;
            }
            
            /* Ordered list styling for steps */
            ol {
                counter-reset: step-counter;
                list-style: none;
                padding-left: 0;
            }
            ol li {
                counter-increment: step-counter;
                position: relative;
                padding-left: 45px;
                margin-bottom: 20px;
            }
            ol li::before {
                content: counter(step-counter);
                position: absolute;
                left: 0;
                top: 0;
                background: linear-gradient(135deg, #FFA500, #FF4500);
                color: white;
                width: 30px;
                height: 30px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: 600;
                font-size: 14px;
                font-family: 'Outfit', sans-serif;
                box-shadow: 0 2px 8px rgba(255, 165, 0, 0.3);
            }
            
            pre code { background: transparent; padding: 0; color: #eee; }

            /* Code Block Header with Glass */
            .code-header {
                background: rgba(40, 40, 40, 0.9);
                backdrop-filter: blur(15px) saturate(1.5);
                -webkit-backdrop-filter: blur(15px) saturate(1.5);
                padding: 8px 16px;
                border-top-left-radius: 12px;
                border-top-right-radius: 12px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-family: 'Outfit', sans-serif;
                font-size: 12px;
                color: rgba(255, 255, 255, 0.6);
                border-bottom: 1px solid rgba(255,255,255,0.05);
                box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
            }
            .copy-btn {
                background: rgba(255,255,255,0.1);
                backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 6px;
                color: #fff;
                padding: 5px 10px;
                cursor: pointer;
                font-size: 10px;
                transition: all 0.2s;
                font-weight: 500;
            }
            .copy-btn:hover {
                background: rgba(255,255,255,0.15);
                border-color: rgba(255, 255, 255, 0.2);
            }
            .copy-btn:active { 
                transform: scale(0.95); 
                background: rgba(255,255,255,0.2); 
            }

            /* GitHub Alerts / Callouts with Glass */
            .alert {
                padding: 14px 18px;
                margin: 18px 0;
                border-radius: 14px;
                border-left: 4px solid;
                font-size: 16px;
                backdrop-filter: blur(20px) saturate(1.5);
                -webkit-backdrop-filter: blur(20px) saturate(1.5);
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.05);
                border: 1px solid rgba(255, 255, 255, 0.08);
                border-left-width: 4px;
            }
            .alert-title {
                font-weight: 600;
                margin-bottom: 4px;
                display: flex;
                align-items: center;
                gap: 8px;
                text-transform: uppercase;
                font-size: 13px;
                letter-spacing: 0.5px;
            }
            .alert-note { background: rgba(56, 139, 253, 0.1); border-left-color: #388bfd; color: #adbac7; }
            .alert-tip { background: rgba(63, 185, 80, 0.1); border-left-color: #3fb950; color: #adbac7; }
            .alert-important { background: rgba(175, 82, 222, 0.1); border-left-color: #af52de; color: #adbac7; }
            .alert-warning { background: rgba(210, 153, 34, 0.1); border-left-color: #d29922; color: #adbac7; }
            .alert-caution { background: rgba(248, 81, 73, 0.1); border-left-color: #f85149; color: #adbac7; }
            
            /* Task Lists */
            ul.contains-task-list {
                list-style-type: none;
                padding-left: 0;
            }
            .task-list-item {
                display: flex;
                align-items: flex-start;
                gap: 10px;
                margin-bottom: 8px;
            }
            .task-list-item-checkbox {
                margin-top: 6px;
                appearance: none;
                -webkit-appearance: none;
                width: 16px;
                height: 16px;
                border: 2px solid rgba(255, 165, 0, 0.5);
                border-radius: 4px;
                position: relative;
                cursor: pointer;
            }
            .task-list-item-checkbox:checked {
                background-color: #FFA500;
                border-color: #FFA500;
            }
            .task-list-item-checkbox:checked::after {
                content: '';
                position: absolute;
                left: 4px;
                top: 1px;
                width: 4px;
                height: 8px;
                border: solid white;
                border-width: 0 2px 2px 0;
                transform: rotate(45deg);
            }

            /* Tables */
            table {
                width: 100%;
                border-collapse: separate;
                border-spacing: 0;
                margin: 20px 0;
                background: rgba(255, 255, 255, 0.05);
                border-radius: 12px;
                overflow: hidden;
                border: 1px solid rgba(255, 255, 255, 0.1);
            }
            th, td {
                padding: 12px 16px;
                text-align: left;
                border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            }
            th {
                background: rgba(255, 255, 255, 0.1);
                font-weight: 600;
                color: #fff;
                font-family: 'Outfit', sans-serif;
            }
            tr:last-child td {
                border-bottom: none;
            }
            tr:hover td {
                background: rgba(255, 255, 255, 0.05);
            }

            /* Blockquotes */
            blockquote {
                margin: 20px 0;
                padding: 16px 24px;
                background: rgba(255, 165, 0, 0.05);
                border-left: 4px solid #FFA500;
                border-radius: 0 12px 12px 0;
                font-style: italic;
                color: rgba(255, 255, 255, 0.9);
            }
            
            /* Horizontal Rule */
            hr {
                border: none;
                height: 1px;
                background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
                margin: 32px 0;
            }
            
            /* Keyboard Keys */
            kbd {
                background: rgba(255, 255, 255, 0.1);
                border: 1px solid rgba(255, 255, 255, 0.2);
                border-radius: 6px;
                padding: 2px 6px;
                font-family: 'SF Mono', 'Menlo', monospace;
                font-size: 0.85em;
                box-shadow: 0 2px 0 rgba(255, 255, 255, 0.05);
                color: #fff;
            }
        </style>
        """#
        
        let js = #"""
        <script>
            window.MathJax = {
              tex: {
                inlineMath: [['$', '$'], ['\\(', '\\)']],
                displayMath: [['$$', '$$'], ['\\[', '\\]']],
                processEscapes: true
              },
              startup: {
                typeset: false // We will manually typeset to ensure clean rendering
              }
            };
        </script>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
        <script src="https://unpkg.com/lucide@latest"></script>
        <script>
            // Initialize Mermaid
            try {
                mermaid.initialize({
                    startOnLoad: false,
                    securityLevel: 'loose',
                    theme: 'dark',
                    flowchart: { useMaxWidth: true, htmlLabels: true, curve: 'basis' }
                });
            } catch (e) { console.error('Mermaid init error:', e); }

            function sendHeight() {
                // Use offsetHeight of the content wrapper for more stability
                const content = document.getElementById('content');
                const height = Math.max(content.offsetHeight + 10, 50);
                window.webkit.messageHandlers.heightHandler.postMessage(height);
            }
             function copyToClipboard(text, btn) {
                try {
                    const temp = document.createElement('textarea');
                    temp.value = text;
                    document.body.appendChild(temp);
                    temp.select();
                    document.execCommand('copy');
                    document.body.removeChild(temp);
                    
                    const oldText = btn.innerText;
                    btn.innerText = 'Copied!';
                    btn.style.color = '#FFA500';
                    setTimeout(() => {
                        btn.innerText = oldText;
                        btn.style.color = '#fff';
                    }, 2000);
                } catch (e) { console.error('Copy error:', e); }
            }

            function runCode(btn) {
                const container = btn.closest('.code-container');
                const lang = container.getAttribute('data-lang');
                const code = atob(container.getAttribute('data-code'));
                window.webkit.messageHandlers.runHandler.postMessage({lang: lang, code: code});
            }
             async function beautifyMathContent() {
                const contentDiv = document.getElementById('content');
                
                // 1. Detect and style step headers FIRST (before adding math)
                const paragraphs = contentDiv.querySelectorAll('p');
                paragraphs.forEach(p => {
                    const text = p.textContent.trim();
                    // Match patterns like "Numerator:", "Denominator:", "Step 1:", etc.
                    if (/^(Numerator|Denominator|Step \d+|Real part|Imaginary part|Simplify|Solution|Calculate|Combine|Multiply|Substitute)[:\s]/i.test(text)) {
                        const colonIndex = p.innerHTML.indexOf(':');
                        if (colonIndex > -1) {
                            const title = p.innerHTML.substring(0, colonIndex);
                            const content = p.innerHTML.substring(colonIndex + 1);
                            p.outerHTML = `<div class="math-step">
                                <div class="math-step-title">${title}</div>
                                <div class="math-step-content">${content.trim()}</div>
                            </div>`;
                        }
                    }
                });
                
                // 2. Convert plain text fractions (not in math mode) to LaTeX
                // This needs to avoid existing MathJax elements
                const textNodes = document.createTreeWalker(
                    contentDiv,
                    NodeFilter.SHOW_TEXT,
                    null
                );
                
                let nodesToReplace = [];
                let node;
                while (node = textNodes.nextNode()) {
                    if (node.parentElement && !node.parentElement.closest('mjx-container, .MathJax')) {
                        const matches = [...node.textContent.matchAll(/\b(-?\d+)\/(-?\d+)\b/g)];
                        if (matches.length > 0) {
                            nodesToReplace.push({node, matches});
                        }
                    }
                }
                
                nodesToReplace.forEach(({node, matches}) => {
                    let html = node.textContent;
                    matches.forEach(match => {
                        html = html.replace(match[0], `\\(\\frac{${match[1]}}{${match[2]}}\\)`);
                    });
                    const span = document.createElement('span');
                    span.innerHTML = html;
                    node.parentElement.replaceChild(span, node);
                });
                
                // 3. Wrap "The final answer is..." in special styling
                contentDiv.innerHTML = contentDiv.innerHTML.replace(
                    /The final answer is\s+\$\\boxed\{([^}]+)\}\$\.?/gi,
                    '<div class="final-answer"><div class="final-answer-label">✨ Final Answer</div><div style="font-size: 24px; margin-top: 8px;">\\[\\boxed{$1}\\]</div></div>'
                );
                
                // Also catch variations
                contentDiv.innerHTML = contentDiv.innerHTML.replace(
                    /The final answer is\s+\$([^$]+)\$\.?/gi,
                    '<div class="final-answer"><div class="final-answer-label">✨ Final Answer</div><div style="font-size: 24px; margin-top: 8px;">\\[\\boxed{$1}\\]</div></div>'
                );
                
                // 4. Enhance "Since..." statements (avoid math elements)
                const sinceRegex = /(\bSince\s+)([^,\.]+)/gi;
                contentDiv.innerHTML = contentDiv.innerHTML.replace(
                    sinceRegex,
                    '<strong style="color: #FFB84D; font-weight: 600;">Since $2</strong>'
                );
                
                // 5. Re-render MathJax after all changes
                if (window.MathJax && window.MathJax.typesetPromise) {
                    try { 
                        await window.MathJax.typesetPromise([contentDiv]); 
                    } catch(e) {
                        console.error('MathJax beautify error:', e);
                    }
                }
            }

            async function render() {
                try {
                    const rawContent = document.getElementById('raw-content').value;
                    if (!rawContent) {
                        sendHeight();
                        return;
                    }
                    
                    const renderer = new marked.Renderer();
                    
                    // Image renderer for gallery support
                    renderer.image = (hrefOrToken, title, text) => {
                        let href = "";
                        let alt = "";
                        let imageTitle = "";
                        
                        if (typeof hrefOrToken === 'object' && hrefOrToken !== null) {
                            href = hrefOrToken.href;
                            alt = hrefOrToken.text || "";
                            imageTitle = hrefOrToken.title || "";
                        } else {
                            href = hrefOrToken;
                            alt = text || "";
                            imageTitle = title || "";
                        }
                        
                        return `<img src="${href}" alt="${alt}" title="${imageTitle}" loading="lazy" data-gallery-item="true">`;
                    };
                    
                    renderer.link = (hrefOrToken, title, text) => {
                        let href = "";
                        let linkText = "";
                        
                        if (typeof hrefOrToken === 'object' && hrefOrToken !== null) {
                            href = hrefOrToken.href;
                            linkText = hrefOrToken.text;
                        } else {
                            href = hrefOrToken;
                            linkText = text;
                        }
                        
                        let domain = "Link";
                        try { 
                            const url = new URL(href);
                            domain = url.hostname; 
                        } catch(e) {}
                        
                        const faviconUrl = `https://www.google.com/s2/favicons?sz=128&domain=${domain}`;
                        
                        return `<a href="${href}" class="link-card" target="_blank">
                            <div class="link-icon">
                                <img src="${faviconUrl}" style="width: 24px; height: 24px; border-radius: 6px;" onerror="this.src='https://www.gstatic.com/images/icons/material/system/2x/link_white_24dp.png'">
                            </div>
                            <div class="link-content">
                                <div class="link-title">${linkText || 'View Link'}</div>
                                <div class="link-url">${domain}</div>
                            </div>
                        </a>`;
                    };

                    renderer.code = (tokenOrCode, lang) => {
                    let code = "";
                    let language = "";
                    
                    if (typeof tokenOrCode === 'object' && tokenOrCode !== null) {
                        code = tokenOrCode.text;
                        language = (tokenOrCode.lang || 'code').trim().toLowerCase();
                    } else {
                        code = tokenOrCode;
                        language = (lang || 'code').trim().toLowerCase();
                    }

                    if (language === 'mermaid') {
                        // Use Base64 to store the raw code safely, avoiding HTML parsing issues
                        const encodedCode = btoa(unescape(encodeURIComponent(code.trim())));
                        return `<div class="mermaid-container" data-code="${encodedCode}" style="margin: 16px 0; min-height: 50px; opacity: 0; transition: opacity 0.3s;"></div>`;
                    }

                    // Check if this is a math block (latex, math, tex)
                    if (language === 'math' || language === 'latex' || language === 'tex') {
                        return `<div style="margin: 20px 0; text-align: center;">$$${code}$$</div>`;
                    }

                    // Detect if code block contains mostly math symbols (heuristic)
                    const mathIndicators = /[\\{}^_=∫∑∏√±≤≥≠×÷∞∂∇]/;
                    const hasLotsOfMath = (code.match(/[\\{}^_]/g) || []).length > 3;
                    if (!language && (mathIndicators.test(code) || hasLotsOfMath)) {
                        return `<div style="margin: 20px 0; text-align: center;">$$${code}$$</div>`;
                    }

                    const displayLang = language.split('{')[0].trim().toUpperCase() || 'CODE';
                    // Use Base64 to safely store the code in a data attribute
                    const encodedCode = btoa(unescape(encodeURIComponent(code)));
                    
                    let runButton = "";
                    const runnableLangs = ['html', 'css', 'javascript', 'js', 'react', 'vue', 'p5js'];
                    if (runnableLangs.includes(language)) {
                        runButton = `<button class="copy-btn" style="margin-right: 8px; background: rgba(255,165,0,0.2); border-color: rgba(255,165,0,0.4);" onclick="runCode(this)">Run</button>`;
                    }

                    const escapedCodeForCopy = code.replace(/\\/g, '\\\\').replace(/`/g, '\\`').replace(/\$/g, '\\$');

                    return `<div class="code-container" data-lang="${language}" data-code="${encodedCode}" style="margin: 16px 0; border-radius: 12px; overflow: hidden; border: 1px solid rgba(255,255,255,0.1);">
                        <div class="code-header">
                            <span>${displayLang}</span>
                            <div style="display: flex; gap: 4px;">
                                ${runButton}
                                <button class="copy-btn" onclick="copyToClipboard(\`${escapedCodeForCopy}\`, this)">Copy</button>
                            </div>
                        </div>
                        <pre style="margin:0; border:none; border-radius:0;"><code>${code}</code></pre>
                    </div>`;
                };
                 // Configure Marked
                if (marked.use) {
                    marked.use({ renderer });
                } else {
                    marked.setOptions({ renderer: renderer, breaks: true, gfm: true });
                }

                let processedContent = rawContent.replace(/> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]([\s\S]*?)(?=(?:\n> |\n\n|$))/gi, (match, type, content) => {
                    return `<div class="alert alert-${type.toLowerCase()}">
                        <div class="alert-title">${type}</div>
                        ${content.trim().replace(/^> /gm, '')}
                    </div>`;
                });

                // Parse Markdown first
                let htmlContent = marked.parse(processedContent);

                // Process progress bars: [progress:75] or [progress:75:Timeline Complete]
                // Use sparingly - only for timelines, schedules, and quantifiable metrics
                htmlContent = htmlContent.replace(/\[progress:(\d+)(?::([^\]]+))?\]/g, (match, value, label) => {
                    const labelHtml = label ? `<div class="progress-label">${label}</div>` : '';
                    return `${labelHtml}<div class="progress-bar">
                        <div class="progress-bar-fill" style="width:0%" data-target="${value}%"></div>
                    </div>`;
                });

                // Process icons: [icon:name]
                // 1. Define aliases for common user terms to Lucide names
                const iconAliases = {
                    'cash': 'banknote',
                    'money': 'banknote',
                    'dollar': 'dollar-sign',
                    'thumbsup': 'thumbs-up',
                    'like': 'thumbs-up',
                    'thumbsdown': 'thumbs-down',
                    'dislike': 'thumbs-down',
                    'celebration': 'party-popper',
                    'party': 'party-popper',
                    'tada': 'party-popper',
                    'rocket': 'rocket',
                    'launch': 'rocket',
                    'fire': 'flame',
                    'flame': 'flame',
                    'heart': 'heart',
                    'love': 'heart',
                    'star': 'star',
                    'check': 'check',
                    'success': 'circle-check',
                    'error': 'circle-x',
                    'warning': 'triangle-alert',
                    'alert': 'triangle-alert',
                    'info': 'info',
                    'question': 'circle-help',
                    'help': 'circle-help',
                    'user': 'user',
                    'person': 'user',
                    'settings': 'settings',
                    'gear': 'settings',
                    'calendar': 'calendar',
                    'time': 'clock',
                    'clock': 'clock',
                    'search': 'search',
                    'home': 'house',
                    'map': 'map-pin',
                    'location': 'map-pin',
                    'edit': 'pencil',
                    'trash': 'trash-2',
                    'delete': 'trash-2',
                    'lock': 'lock',
                    'unlock': 'unlock'
                };

                htmlContent = htmlContent.replace(/\[icon:([a-z0-9-]+)\]/g, (match, name) => {
                    const iconName = iconAliases[name] || name;
                    return `<i data-lucide="${iconName}" class="lucide-icon"></i>`;
                });

                document.getElementById('content').innerHTML = htmlContent;
                
                // --- INITIALIZE LUCIDE ICONS ---
                if (typeof lucide !== 'undefined') {
                    lucide.createIcons();
                }
                
                // --- CREATE IMAGE GALLERIES ---
                // Group consecutive images into galleries
                const contentDiv = document.getElementById('content');
                const images = contentDiv.querySelectorAll('img[data-gallery-item="true"]');
                const galleries = [];
                let currentGallery = [];
                
                images.forEach((img, index) => {
                    // Check if this image is followed by another image (with only whitespace between)
                    const parent = img.parentElement;
                    const nextSibling = img.parentElement.nextElementSibling;
                    
                    currentGallery.push(img);
                    
                    // If next sibling doesn't contain an image, or it's the last image, finalize gallery
                    const hasNextImage = nextSibling && nextSibling.querySelector('img[data-gallery-item="true"]');
                    
                    if (!hasNextImage || index === images.length - 1) {
                        if (currentGallery.length > 1) {
                            galleries.push([...currentGallery]);
                        }
                        currentGallery = [];
                    }
                });
                
                // Convert galleries
                galleries.forEach(galleryImages => {
                    if (galleryImages.length < 2) return;
                    
                    const firstImg = galleryImages[0];
                    const galleryDiv = document.createElement('div');
                    galleryDiv.className = 'image-gallery';
                    
                    galleryImages.forEach(img => {
                        const clone = img.cloneNode(true);
                        galleryDiv.appendChild(clone);
                        img.parentElement.remove();
                    });
                    
                    // Insert gallery where first image was
                    contentDiv.appendChild(galleryDiv);
                });
                
                // --- ANIMATE PROGRESS BARS ---
                setTimeout(() => {
                    document.querySelectorAll('.progress-bar-fill').forEach(bar => {
                        bar.style.width = bar.getAttribute('data-target');
                    });
                }, 100);
                
                // --- RENDER MERMAID DIAGRAMS ---
                if (typeof mermaid !== 'undefined') {
                    const containers = document.querySelectorAll('.mermaid-container');
                    for (const el of containers) {
                        if (el.getAttribute('data-processed')) continue;
                        try {
                            // 1. Decode base64 code
                            const encoded = el.getAttribute('data-code');
                            let diagramCode = decodeURIComponent(escape(atob(encoded)));
                            
                            // 2. DIAGRAM HEALER: Fix common AI mistakes
                            
                            // A. Wrap literal newlines in labels (Mermaid hates literal newlines in nodes)
                            // This finds [ "Text\nText" ] and turns it into [ "Text<br/>Text" ]
                            diagramCode = diagramCode.replace(/(\[[^\]]*\]|\([^)]*\)|\{[^}]*\})/g, (match) => {
                                return match.replace(/\n/g, '<br/>').replace(/\s{2,}/g, ' ');
                            });

                            // B. Ensure graph type exists
                            // Updated to include timeline, mindmap, gitGraph, C4Context, sankey-beta, block-beta
                            if (!/^(graph|flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram|erDiagram|journey|pie|quadrantChart|timeline|mindmap|gitGraph|C4Context|sankey-beta|block-beta|xychart-beta)/i.test(diagramCode.trim())) {
                                diagramCode = "graph TD\n" + diagramCode;
                            }

                            // C. Quote unquoted labels with special characters
                            diagramCode = diagramCode.replace(/(\[|\(|\{)([^"\]\)\}\n]+)(\]|\)|\})/g, (match, open, content, close) => {
                                let trimmed = content.trim();
                                if (trimmed.includes('<') || trimmed.includes('>') || trimmed.includes('&') || trimmed.includes(' ')) {
                                    return `${open}"${trimmed.replace(/"/g, "'")}"${close}`;
                                }
                                return match;
                            });
                            
                            // 3. Render
                            const id = 'mermaid-' + Math.random().toString(36).substr(2, 9);
                            const mermaidDiv = document.createElement('div');
                            mermaidDiv.className = 'mermaid';
                            mermaidDiv.id = id;
                            mermaidDiv.textContent = diagramCode;
                            el.innerHTML = '';
                            el.appendChild(mermaidDiv);
                            
                            await mermaid.init(undefined, mermaidDiv);
                            
                            el.setAttribute('data-processed', 'true');
                            el.style.opacity = '1';
                        } catch (e) { 
                            console.error('Mermaid render error:', e); 
                            el.style.opacity = '1';
                            el.innerHTML = `<div style="color:#ff4444; font-size:12px; border:1px dashed #ff4444; padding:8px;">Mermaid Error: Click to see code<pre style="display:none;">${atob(el.getAttribute('data-code'))}</pre></div>`;
                            el.onclick = () => { el.querySelector('pre').style.display = 'block'; };
                        }
                    }
                }

                // --- RENDER MATHJAX FIRST ---
                if (window.MathJax && window.MathJax.typesetPromise) {
                    try { await window.MathJax.typesetPromise(); } catch(e) {}
                }

                // --- BEAUTIFY MATH CONTENT (after initial MathJax) ---
                await beautifyMathContent();
            } catch (e) {
                console.error('Global Render Error:', e);
            } finally {
                sendHeight();
                // Send height again after a short delay for dynamic content adjustments
                setTimeout(sendHeight, 200);
            }
        }
        
        function updateContent(base64Text) {
            try {
                if (!base64Text) return;
                const rawContent = decodeURIComponent(escape(window.atob(base64Text)));
                document.getElementById('raw-content').value = rawContent;
                render();
            } catch (e) { 
                console.error('Update Content error:', e);
                sendHeight();
            }
        }

        window.onload = () => { setTimeout(render, 50); };
        new ResizeObserver(() => sendHeight()).observe(document.body);
        </script>
        """#
        
        // Only escape < that aren't part of HTML tags, but preserve $ for math
        let safeContent = content
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<(?![a-zA-Z/])", with: "&lt;", options: .regularExpression)
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            \(css)
            \(js)
        </head>
        <body>
            <div id="content"></div>
            <textarea id="raw-content" style="display:none;">\(safeContent)</textarea>
        </body>
        </html>
        """
    }
}
