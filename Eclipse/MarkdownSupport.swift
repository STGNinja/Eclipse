import SwiftUI

struct EnhancedMarkdownView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(parseBlocks(text)) { block in
                switch block.type {
                case .divider:
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.2),
                                    Color.orange.opacity(0.3),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .padding(.vertical, 8)
                case .code(let language, let code):
                    CodeBlockView(language: language, code: code)
                case .table(let headers, let rows):
                    MarkdownTableView(headers: headers, rows: rows)
                case .listItem(let marker, let content):
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        formatText(content)
                    }
                    .padding(.leading, 4)
                case .numberedItem(let number, let content):
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(number).")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(minWidth: 24, alignment: .trailing)
                        formatText(content)
                    }
                    .padding(.leading, 4)
                case .blockquote(let content):
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 4)
                        formatText(content)
                            .foregroundStyle(.white.opacity(0.95))
                            .italic()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                case .header(let level, let content):
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content)
                            .font(.system(size: headerSize(for: level), weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: headerGradient(for: level),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(0.5)

                        // Decorative underline for top-level headers
                        if level == 1 {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.2), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 2)
                                .frame(maxWidth: 120)
                        }
                    }
                    .padding(.top, level == 1 ? 16 : 12)
                    .padding(.bottom, 4)
                case .paragraph(let content):
                    // Check if this is a mathematical expression line (contains = and math symbols)
                    if isMathExpression(content) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("=")
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundStyle(Color.orange.opacity(0.7))
                                .frame(width: 20)
                            formatText(content.replacingOccurrences(of: "^=\\s*", with: "", options: .regularExpression))
                                .font(.system(size: 16, design: .serif))
                        }
                        .padding(.leading, 24)
                        .padding(.vertical, 2)
                    } else {
                        formatText(content)
                    }
                }
            }
        }
    }
    
    private func formatText(_ content: String) -> some View {
        // Process inline math first, then handle markdown formatting
        let processedContent = processInlineMath(content)
        let styledContent = processInlineFormatting(processedContent)

        return Text(styledContent)
            .font(.system(size: 17, design: .serif))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func processInlineFormatting(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        // Handle `inline code` - do this first before other formatting
        if let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = codeRegex.matches(in: text, options: [], range: nsRange)

            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: text),
                   let contentRange = Range(match.range(at: 1), in: text) {
                    let content = String(text[contentRange])

                    if let attrRange = Range(matchRange, in: attributed) {
                        attributed.replaceSubrange(attrRange, with: AttributedString(content))
                        if let codeRange = attributed.range(of: content) {
                            attributed[codeRange].font = .system(size: 15, weight: .medium, design: .monospaced)
                            attributed[codeRange].foregroundColor = Color.cyan
                            attributed[codeRange].backgroundColor = Color.cyan.opacity(0.15)
                        }
                    }
                }
            }
        }

        // Handle **bold** text
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*", options: []) {
            let currentText = String(attributed.characters)
            let nsRange = NSRange(currentText.startIndex..., in: currentText)
            let matches = boldRegex.matches(in: currentText, options: [], range: nsRange)

            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: currentText),
                   let contentRange = Range(match.range(at: 1), in: currentText) {
                    let content = String(currentText[contentRange])

                    if let attrRange = Range(matchRange, in: attributed) {
                        attributed.replaceSubrange(attrRange, with: AttributedString(content))
                        if let boldRange = attributed.range(of: content) {
                            attributed[boldRange].font = .system(size: 17, weight: .bold, design: .serif)
                            attributed[boldRange].foregroundColor = .white
                        }
                    }
                }
            }
        }

        // Handle *italic* text (but not part of **)
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)([^*]+)\\*(?!\\*)", options: []) {
            let currentText = String(attributed.characters)
            let nsRange = NSRange(currentText.startIndex..., in: currentText)
            let matches = italicRegex.matches(in: currentText, options: [], range: nsRange)

            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: currentText),
                   let contentRange = Range(match.range(at: 1), in: currentText) {
                    let content = String(currentText[contentRange])

                    if let attrRange = Range(matchRange, in: attributed) {
                        attributed.replaceSubrange(attrRange, with: AttributedString(content))
                        if let italicRange = attributed.range(of: content) {
                            attributed[italicRange].font = .system(size: 17, design: .serif).italic()
                            attributed[italicRange].foregroundColor = .white.opacity(0.9)
                        }
                    }
                }
            }
        }

        return attributed
    }

    private func headerSize(for level: Int) -> CGFloat {
        switch level {
        case 1: return 28
        case 2: return 24
        case 3: return 20
        default: return 18
        }
    }

    private func headerGradient(for level: Int) -> [Color] {
        switch level {
        case 1: return [.white, .white.opacity(0.9), .orange.opacity(0.7)]
        case 2: return [.white, .white.opacity(0.85)]
        default: return [.white.opacity(0.95), .white.opacity(0.8)]
        }
    }

    private func isMathExpression(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        // Check if line starts with = and contains math notation
        if trimmed.hasPrefix("=") {
            // Contains common math symbols or fractions
            return trimmed.contains("/") ||
                   trimmed.contains("i") ||
                   trimmed.contains("+") ||
                   trimmed.contains("-") ||
                   trimmed.contains("*") ||
                   trimmed.contains("^")
        }

        return false
    }

    private func processInlineMath(_ text: String) -> String {
        // Replace inline math $...$ with highlighted version
        // This is a simple approach - for production you'd want a proper LaTeX renderer
        var result = text

        // Handle $\boxed{...}$ pattern specifically (common in math answers)
        let boxedPattern = "\\$\\\\boxed\\{([^}]+)\\}\\$"
        if let regex = try? NSRegularExpression(pattern: boxedPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range)

            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let content = String(result[contentRange])
                    // Replace with formatted version
                    result.replaceSubrange(matchRange, with: "📦 \(content)")
                }
            }
        }

        // Handle general inline math $...$ (but not $$)
        let inlineMathPattern = "(?<!\\$)\\$(?!\\$)([^$]+)\\$(?!\\$)"
        if let regex = try? NSRegularExpression(pattern: inlineMathPattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range)

            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: result),
                   let contentRange = Range(match.range(at: 1), in: result) {
                    let content = String(result[contentRange])
                    // Keep the content but make it more readable
                    result.replaceSubrange(matchRange, with: "⟨\(content)⟩")
                }
            }
        }

        return result
    }
    
    private func parseBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentCodeBlock: (lang: String, code: String)?
        var currentTable: (headers: [String], rows: [[String]])?
        var currentMathBlock: String?

        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // MATH BLOCKS (LaTeX) - Handle \begin{...}...\end{...} environments
            if trimmed.hasPrefix("\\begin{") {
                // Extract environment name (e.g., "align*", "equation", etc.)
                if let endRange = trimmed.range(of: "}") {
                    let envName = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 7)..<endRange.lowerBound])
                    let endMarker = "\\end{\(envName)}"

                    var mathContent = trimmed + "\n"
                    i += 1

                    // Collect lines until we find the matching \end{...}
                    while i < lines.count {
                        let envLine = lines[i]
                        mathContent += envLine + "\n"

                        if envLine.trimmingCharacters(in: .whitespaces).hasPrefix(endMarker) {
                            // Found the end, save as LaTeX block
                            blocks.append(MarkdownBlock(type: .code(language: "LaTeX", code: mathContent.trimmingCharacters(in: .whitespacesAndNewlines))))
                            i += 1
                            break
                        }
                        i += 1
                    }
                    continue
                }
            }

            // MATH BLOCKS (LaTeX) - Handle $$ ... $$ delimiter style
            if trimmed == "$$" {
                if let mathState = currentMathBlock {
                    // End math block - render as code block with "LaTeX" language
                    blocks.append(MarkdownBlock(type: .code(language: "LaTeX", code: mathState.trimmingCharacters(in: .whitespacesAndNewlines))))
                    currentMathBlock = nil
                } else {
                    currentMathBlock = ""
                }
                i += 1
                continue
            }

            if var mathState = currentMathBlock {
                mathState += line + "\n"
                currentMathBlock = mathState
                i += 1
                continue
            }

            // CODE BLOCKS
            if trimmed.hasPrefix("```") {
                if let codeState = currentCodeBlock {
                    blocks.append(MarkdownBlock(type: .code(language: codeState.lang, code: codeState.code.trimmingCharacters(in: .whitespacesAndNewlines))))
                    currentCodeBlock = nil
                } else {
                    let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    currentCodeBlock = (lang, "")
                }
                i += 1
                continue
            }
            
            if var codeState = currentCodeBlock {
                codeState.code += line + "\n"
                currentCodeBlock = codeState
                i += 1
                continue
            }
            
            // SKIP EMPTY
            if trimmed.isEmpty {
                // If we were parsing a table, end it?
                // Actually table parser handles its own continuation
                if let table = currentTable {
                     blocks.append(MarkdownBlock(type: .table(headers: table.headers, rows: table.rows)))
                     currentTable = nil
                }
                i += 1
                continue
            }
            
            // TABLES
            // Look ahead for separator line |---| if not currently in table
            if currentTable == nil && trimmed.starts(with: "|") && i + 1 < lines.count {
                let nextLine = lines[i+1].trimmingCharacters(in: .whitespaces)
                if nextLine.starts(with: "|") && nextLine.contains("-") {
                    // Start of table
                    let headers = parseTableLine(trimmed)
                    currentTable = (headers, [])
                    i += 2 // Skip header and separator
                    continue
                }
            }
            
            if var table = currentTable {
                if trimmed.starts(with: "|") {
                    let row = parseTableLine(trimmed)
                    table.rows.append(row)
                    currentTable = table
                    i += 1
                    continue
                } else {
                    // End of table
                    blocks.append(MarkdownBlock(type: .table(headers: table.headers, rows: table.rows)))
                    currentTable = nil
                    // Don't skip index, re-evaluate line as normal
                }
            }
            
            // NORMAL BLOCKS - Headers (support up to #### level 4)
            if trimmed.hasPrefix("#### ") {
                blocks.append(MarkdownBlock(type: .header(level: 4, content: String(trimmed.dropFirst(5)))))
            } else if trimmed.hasPrefix("### ") {
                blocks.append(MarkdownBlock(type: .header(level: 3, content: String(trimmed.dropFirst(4)))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(MarkdownBlock(type: .header(level: 2, content: String(trimmed.dropFirst(3)))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(MarkdownBlock(type: .header(level: 1, content: String(trimmed.dropFirst(2)))))
            } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                // Horizontal rule / divider
                blocks.append(MarkdownBlock(type: .divider))
            } else if trimmed.hasPrefix("> ") {
                 blocks.append(MarkdownBlock(type: .blockquote(content: String(trimmed.dropFirst(2)))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(MarkdownBlock(type: .listItem(marker: "•", content: String(trimmed.dropFirst(2)))))
            } else if let match = trimmed.range(of: "^\\d+\\. ", options: .regularExpression) {
                let numberStr = String(trimmed[match]).trimmingCharacters(in: .whitespacesAndNewlines).dropLast()
                let content = String(trimmed[match.upperBound...])
                blocks.append(MarkdownBlock(type: .numberedItem(number: String(numberStr), content: content)))
            } else {
                blocks.append(MarkdownBlock(type: .paragraph(content: trimmed)))
            }
            
            i += 1
        }
        
        if let codeState = currentCodeBlock {
             blocks.append(MarkdownBlock(type: .code(language: codeState.lang, code: codeState.code.trimmingCharacters(in: .whitespacesAndNewlines))))
        }
        if let table = currentTable {
             blocks.append(MarkdownBlock(type: .table(headers: table.headers, rows: table.rows)))
        }
        if let mathState = currentMathBlock {
            blocks.append(MarkdownBlock(type: .code(language: "LaTeX", code: mathState.trimmingCharacters(in: .whitespacesAndNewlines))))
        }

        return blocks
    }
    
    private func parseTableLine(_ line: String) -> [String] {
        // Simple pipe split, remove first/last empty
        var items = line.components(separatedBy: "|")
        if items.first?.trimmingCharacters(in: .whitespaces).isEmpty ?? false { items.removeFirst() }
        if items.last?.trimmingCharacters(in: .whitespaces).isEmpty ?? false { items.removeLast() }
        return items.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: BlockType

    enum BlockType {
        case code(language: String, code: String)
        case table(headers: [String], rows: [[String]])
        case listItem(marker: String, content: String)
        case numberedItem(number: String, content: String)
        case header(level: Int, content: String)
        case blockquote(content: String)
        case paragraph(content: String)
        case divider
    }
}

// MARK: - Components

struct MarkdownTableView: View {
    let headers: [String]
    let rows: [[String]]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                // Header Row
                GridRow {
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                        renderMarkdown(header)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .frame(minWidth: 120, maxWidth: 300, alignment: .leading)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Data Rows
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(0..<headers.count, id: \.self) { colIndex in
                            let cellContent = colIndex < row.count ? row[colIndex] : ""
                            renderMarkdown(cellContent)
                                .font(.system(size: 15, design: .serif))
                                .minimumScaleFactor(0.85) // Dynamic font size adjustment
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .frame(minWidth: 120, maxWidth: 300, alignment: .leading)
                                .layoutPriority(1) // Ensure text expands row height
                        }
                    }
                    .background(rowIndex % 2 == 0 ? Color.white.opacity(0.05) : Color.clear)
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    private func renderMarkdown(_ text: String) -> Text {
        if let attributed = try? AttributedString(markdown: text) {
            return Text(attributed)
        }
        return Text(text)
    }
}

struct CodeBlockView: View {
    let language: String
    let code: String

    private var isLaTeX: Bool {
        language.lowercased() == "latex"
    }

    private var headerBackgroundColor: Color {
        isLaTeX ? Color.orange.opacity(0.15) : Color.black.opacity(0.3)
    }

    private var labelColor: Color {
        isLaTeX ? Color.orange.opacity(0.8) : Color.white.opacity(0.6)
    }

    private var mainBackgroundColor: Color {
        isLaTeX ? Color.orange.opacity(0.08) : Color.black.opacity(0.2)
    }

    private var strokeColor: Color {
        isLaTeX ? Color.orange.opacity(0.3) : Color.white.opacity(0.1)
    }

    private var fontSize: CGFloat {
        isLaTeX ? 15 : 14
    }

    private var fontDesign: Font.Design {
        isLaTeX ? .serif : .monospaced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                headerView
            }

            codeContentView
        }
        .background(mainBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                if isLaTeX {
                    Image(systemName: "function")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.orange.opacity(0.8))
                }
                Text(language.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(labelColor)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = code
                HapticManager.shared.notification(.success)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(headerBackgroundColor)
    }

    private var codeContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(size: fontSize, design: fontDesign))
                .foregroundStyle(.white.opacity(0.95))
                .padding(14)
        }
    }
}
