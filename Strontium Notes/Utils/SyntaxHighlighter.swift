//
//  SyntaxHighlighter.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

/// Provides syntax highlighting for code blocks
struct SyntaxHighlighter {
    
    /// Highlight code based on language
    static func highlight(code: String, language: String) -> AttributedString {
        let attributed = AttributedString(code)
        
        switch language.lowercased() {
        case "swift":
            return highlightSwift(code)
        case "python":
            return highlightPython(code)
        case "javascript", "js":
            return highlightJavaScript(code)
        case "json":
            return highlightJSON(code)
        default:
            return attributed
        }
    }
    
    private static func highlightSwift(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        
        // Keywords
        let keywords = ["func", "var", "let", "class", "struct", "enum", "if", "else", "for", "while", "return", "import", "guard", "switch", "case"]
        for keyword in keywords {
            highlightPattern(in: &attributed, pattern: "\\b\(keyword)\\b", color: .purple)
        }
        
        // Strings
        highlightPattern(in: &attributed, pattern: "\"[^\"]*\"", color: .red)
        
        // Comments
        highlightPattern(in: &attributed, pattern: "//.*$", color: .green)
        
        return attributed
    }
    
    private static func highlightPython(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        
        // Keywords
        let keywords = ["def", "class", "if", "else", "elif", "for", "while", "return", "import", "from", "as", "try", "except"]
        for keyword in keywords {
            highlightPattern(in: &attributed, pattern: "\\b\(keyword)\\b", color: .purple)
        }
        
        // Strings
        highlightPattern(in: &attributed, pattern: "\"[^\"]*\"", color: .red)
        highlightPattern(in: &attributed, pattern: "'[^']*'", color: .red)
        
        // Comments
        highlightPattern(in: &attributed, pattern: "#.*$", color: .green)
        
        return attributed
    }
    
    private static func highlightJavaScript(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        
        // Keywords
        let keywords = ["function", "var", "let", "const", "if", "else", "for", "while", "return", "class", "import", "export"]
        for keyword in keywords {
            highlightPattern(in: &attributed, pattern: "\\b\(keyword)\\b", color: .purple)
        }
        
        // Strings
        highlightPattern(in: &attributed, pattern: "\"[^\"]*\"", color: .red)
        highlightPattern(in: &attributed, pattern: "'[^']*'", color: .red)
        highlightPattern(in: &attributed, pattern: "`[^`]*`", color: .red)
        
        // Comments
        highlightPattern(in: &attributed, pattern: "//.*$", color: .green)
        
        return attributed
    }
    
    private static func highlightJSON(_ code: String) -> AttributedString {
        var attributed = AttributedString(code)
        
        // Keys
        highlightPattern(in: &attributed, pattern: "\"[^\"]+\"\\s*:", color: .blue)
        
        // Strings
        highlightPattern(in: &attributed, pattern: ":\\s*\"[^\"]*\"", color: .red)
        
        // Numbers
        highlightPattern(in: &attributed, pattern: "\\b\\d+\\.?\\d*\\b", color: .orange)
        
        // Booleans
        highlightPattern(in: &attributed, pattern: "\\b(true|false|null)\\b", color: .purple)
        
        return attributed
    }
    
    private static func highlightPattern(in attributed: inout AttributedString, pattern: String, color: Color) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
        
        let string = String(attributed.characters)
        let nsString = string as NSString
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if let range = Range(match.range, in: string) {
                if let attrRange = Range(range, in: attributed) {
                    attributed[attrRange].foregroundColor = color
                }
            }
        }
    }
}

/// View for displaying syntax-highlighted code
struct SyntaxHighlightedCodeView: View {
    let code: String
    let language: String
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(SyntaxHighlighter.highlight(code: code, language: language))
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .background(Color.tertiaryBackground)
        .cornerRadius(8)
    }
}
