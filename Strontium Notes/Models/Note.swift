//
//  Note.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

/// Represents a markdown note with metadata and content
struct Note: Identifiable, Codable {
    let id: UUID
    let filePath: String
    let title: String
    let frontmatter: [String: AnyCodable]
    let content: String
    let modifiedDate: Date
    let createdDate: Date
    let tags: Set<String>
    let fileSize: Int64
    
    /// Computed property for the note's file name
    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
    
    /// Computed property for the note's directory path
    var directoryPath: String {
        URL(fileURLWithPath: filePath).deletingLastPathComponent().path
    }
    
    /// Computed property for the note's file extension
    var fileExtension: String {
        URL(fileURLWithPath: filePath).pathExtension
    }
    
    /// Computed property to check if the note is a markdown file
    var isMarkdown: Bool {
        fileExtension.lowercased() == "md" || fileExtension.lowercased() == "markdown"
    }
    
    init(filePath: String, title: String, content: String, frontmatter: [String: Any] = [:], folderId: UUID? = nil) {
        self.id = UUID()
        self.filePath = filePath
        self.title = title
        self.content = content
        self.frontmatter = frontmatter.mapValues { AnyCodable($0) }
        self.modifiedDate = Date()
        self.createdDate = Date()
        self.tags = Note.extractTags(from: content)
        self.fileSize = Int64(content.utf8.count)
    }
    
    /// Get all wikilinks from the note content
    func getLinks() -> [String] {
        let pattern = #"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return matches.compactMap { match in
            let targetRange = match.range(at: 1)
            guard targetRange.location != NSNotFound else { return nil }
            return nsString.substring(with: targetRange)
        }
    }
    
    /// Extract tags from note content using #tag syntax
    private static func extractTags(from content: String) -> Set<String> {
        let tagPattern = #"#([a-zA-Z0-9_-]+)"#
        let regex = try! NSRegularExpression(pattern: tagPattern, options: [])
        let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
        
        return Set(matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[range])
        })
    }
    
    /// Computed property for word count
    var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    /// Computed property for character count
    var characterCount: Int {
        return content.count
    }
}

/// Helper struct to handle Any type in Codable contexts
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}