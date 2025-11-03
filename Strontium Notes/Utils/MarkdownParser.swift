//
//  MarkdownParser.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import SwiftUI

/// Utility for parsing and rendering markdown content
struct MarkdownParser {
    
    /// Parse markdown and return attributed string
    static func parse(_ markdown: String) -> AttributedString {
        let attributedString = AttributedString(markdown)
        
        // Apply basic markdown styling
        // This is a simplified implementation - for production, consider using a proper markdown library
        
        return attributedString
    }
    
    /// Extract headers from markdown content
    static func extractHeaders(_ markdown: String) -> [MarkdownHeader] {
        var headers: [MarkdownHeader] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("#") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let level = trimmed.prefix(while: { $0 == "#" }).count
                
                if level > 0 && level <= 6 {
                    let title = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
                    let header = MarkdownHeader(
                        level: level,
                        title: String(title),
                        lineNumber: index
                    )
                    headers.append(header)
                }
            }
        }
        
        return headers
    }
    
    /// Extract code blocks from markdown
    static func extractCodeBlocks(_ markdown: String) -> [CodeBlock] {
        var blocks: [CodeBlock] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var inCodeBlock = false
        var currentLanguage = ""
        var currentCode: [String] = []
        var startLine = 0
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    let block = CodeBlock(
                        language: currentLanguage,
                        code: currentCode.joined(separator: "\n"),
                        startLine: startLine,
                        endLine: index
                    )
                    blocks.append(block)
                    currentCode = []
                    currentLanguage = ""
                    inCodeBlock = false
                } else {
                    // Start of code block
                    inCodeBlock = true
                    startLine = index
                    currentLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
            } else if inCodeBlock {
                currentCode.append(line)
            }
        }
        
        return blocks
    }
    
    /// Extract task list items
    static func extractTasks(_ markdown: String) -> [TaskItem] {
        var tasks: [TaskItem] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        let taskPattern = #"^[\s]*[-*]\s+\[([ xX])\]\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: taskPattern, options: []) else {
            return tasks
        }
        
        for (index, line) in lines.enumerated() {
            let nsString = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let checkboxRange = match.range(at: 1)
                let textRange = match.range(at: 2)
                
                if checkboxRange.location != NSNotFound && textRange.location != NSNotFound {
                    let checkbox = nsString.substring(with: checkboxRange)
                    let text = nsString.substring(with: textRange)
                    
                    let task = TaskItem(
                        text: text,
                        isCompleted: checkbox.lowercased() == "x",
                        lineNumber: index
                    )
                    tasks.append(task)
                }
            }
        }
        
        return tasks
    }
    
    /// Extract links (both markdown and wikilinks)
    static func extractLinks(_ markdown: String) -> [MarkdownLink] {
        var links: [MarkdownLink] = []
        
        // Extract markdown links [text](url)
        let markdownLinkPattern = #"\[([^\]]+)\]\(([^\)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: markdownLinkPattern, options: []) {
            let nsString = markdown as NSString
            let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)
                
                if textRange.location != NSNotFound && urlRange.location != NSNotFound {
                    let text = nsString.substring(with: textRange)
                    let url = nsString.substring(with: urlRange)
                    
                    let link = MarkdownLink(
                        text: text,
                        url: url,
                        type: .markdown,
                        range: match.range
                    )
                    links.append(link)
                }
            }
        }
        
        // Extract wikilinks [[Note Name]]
        let wikilinkPattern = #"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]"#
        if let regex = try? NSRegularExpression(pattern: wikilinkPattern, options: []) {
            let nsString = markdown as NSString
            let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let targetRange = match.range(at: 1)
                let displayRange = match.range(at: 2)
                
                if targetRange.location != NSNotFound {
                    let target = nsString.substring(with: targetRange)
                    let display = displayRange.location != NSNotFound ? nsString.substring(with: displayRange) : target
                    
                    let link = MarkdownLink(
                        text: display,
                        url: target,
                        type: .wikilink,
                        range: match.range
                    )
                    links.append(link)
                }
            }
        }
        
        return links
    }
    
    /// Count words in markdown (excluding code blocks and frontmatter)
    static func wordCount(_ markdown: String) -> Int {
        // Remove code blocks
        var content = markdown
        let codeBlocks = extractCodeBlocks(markdown)
        for block in codeBlocks.reversed() {
            let lines = content.components(separatedBy: .newlines)
            if block.endLine < lines.count {
                var mutableLines = lines
                mutableLines.removeSubrange(block.startLine...block.endLine)
                content = mutableLines.joined(separator: "\n")
            }
        }
        
        // Remove frontmatter
        if content.hasPrefix("---") {
            let lines = content.components(separatedBy: .newlines)
            if let endIndex = lines.dropFirst().firstIndex(where: { $0 == "---" }) {
                content = lines[(endIndex + 1)...].joined(separator: "\n")
            }
        }
        
        // Count words
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return words.count
    }
}

// MARK: - Supporting Types

struct MarkdownHeader: Identifiable {
    let id = UUID()
    let level: Int
    let title: String
    let lineNumber: Int
}

struct CodeBlock: Identifiable {
    let id = UUID()
    let language: String
    let code: String
    let startLine: Int
    let endLine: Int
}

struct TaskItem: Identifiable {
    let id = UUID()
    let text: String
    let isCompleted: Bool
    let lineNumber: Int
}

struct MarkdownLink: Identifiable {
    let id = UUID()
    let text: String
    let url: String
    let type: LinkType
    let range: NSRange
    
    enum LinkType {
        case markdown
        case wikilink
    }
}
