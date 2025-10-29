//
//  SearchModels.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

/// Represents a search index entry for fast querying
struct SearchIndexEntry: Identifiable, Codable {
    let id: UUID
    let noteID: UUID
    let content: String
    let tags: Set<String>
    let title: String
    let lastModified: Date
    let filePath: String
    let wordCount: Int
    
    init(note: Note) {
        self.id = UUID()
        self.noteID = note.id
        self.content = note.content
        self.tags = note.tags
        self.title = note.title
        self.lastModified = note.modifiedDate
        self.filePath = note.filePath
        self.wordCount = note.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}

/// Represents a search result with relevance scoring
struct SearchResult: Identifiable {
    let id: UUID
    let noteID: UUID
    let title: String
    let filePath: String
    let snippet: String
    let relevanceScore: Double
    let matchedTerms: [String]
    let matchRanges: [NSRange]
    let tags: Set<String>
    
    init(noteID: UUID, title: String, filePath: String, snippet: String, relevanceScore: Double, matchedTerms: [String] = [], matchRanges: [NSRange] = [], tags: Set<String> = []) {
        self.id = UUID()
        self.noteID = noteID
        self.title = title
        self.filePath = filePath
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.matchedTerms = matchedTerms
        self.matchRanges = matchRanges
        self.tags = tags
    }
}

/// Represents a search query with advanced operators
struct SearchQuery {
    let rawQuery: String
    let terms: [String]
    let tags: [String]
    let excludedTerms: [String]
    let excludedTags: [String]
    let pathFilters: [String]
    let fileFilters: [String]
    let isExactPhrase: Bool
    let isCaseSensitive: Bool
    
    init(rawQuery: String) {
        self.rawQuery = rawQuery
        
        // Parse the query to extract different components
        var terms: [String] = []
        var tags: [String] = []
        var excludedTerms: [String] = []
        var excludedTags: [String] = []
        var pathFilters: [String] = []
        var fileFilters: [String] = []
        var isExactPhrase = false
        
        // Check for exact phrase (quoted text)
        if rawQuery.hasPrefix("\"") && rawQuery.hasSuffix("\"") {
            isExactPhrase = true
            terms = [String(rawQuery.dropFirst().dropLast())]
        } else {
            // Parse advanced operators
            let components = rawQuery.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            for component in components {
                if component.hasPrefix("tag:") {
                    tags.append(String(component.dropFirst(4)))
                } else if component.hasPrefix("-tag:") {
                    excludedTags.append(String(component.dropFirst(5)))
                } else if component.hasPrefix("path:") {
                    pathFilters.append(String(component.dropFirst(5)))
                } else if component.hasPrefix("file:") {
                    fileFilters.append(String(component.dropFirst(5)))
                } else if component.hasPrefix("-") {
                    excludedTerms.append(String(component.dropFirst()))
                } else {
                    terms.append(component)
                }
            }
        }
        
        self.terms = terms
        self.tags = tags
        self.excludedTerms = excludedTerms
        self.excludedTags = excludedTags
        self.pathFilters = pathFilters
        self.fileFilters = fileFilters
        self.isExactPhrase = isExactPhrase
        self.isCaseSensitive = rawQuery != rawQuery.lowercased()
    }
    
    /// Check if the query is empty
    var isEmpty: Bool {
        terms.isEmpty && tags.isEmpty && pathFilters.isEmpty && fileFilters.isEmpty
    }
    
    /// Check if the query has advanced operators
    var hasAdvancedOperators: Bool {
        !tags.isEmpty || !excludedTerms.isEmpty || !excludedTags.isEmpty || !pathFilters.isEmpty || !fileFilters.isEmpty
    }
}

/// Represents search statistics and metadata
struct SearchStats {
    let totalResults: Int
    let searchTime: TimeInterval
    let indexSize: Int
    let lastIndexUpdate: Date
    
    init(totalResults: Int, searchTime: TimeInterval, indexSize: Int, lastIndexUpdate: Date) {
        self.totalResults = totalResults
        self.searchTime = searchTime
        self.indexSize = indexSize
        self.lastIndexUpdate = lastIndexUpdate
    }
}