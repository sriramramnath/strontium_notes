//
//  SearchEngine.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Concrete implementation of SearchEngineProtocol
@MainActor
class SearchEngine: SearchEngineProtocol, ObservableObject {
    private let searchResultsSubject = PassthroughSubject<[SearchResult], Never>()
    var searchResults: AnyPublisher<[SearchResult], Never> {
        searchResultsSubject.eraseToAnyPublisher()
    }
    
    private let searchStatsSubject = PassthroughSubject<SearchStats, Never>()
    var searchStats: AnyPublisher<SearchStats, Never> {
        searchStatsSubject.eraseToAnyPublisher()
    }
    
    private var searchIndex: [UUID: SearchIndexEntry] = [:]
    private var lastIndexUpdate = Date()
    
    func search(_ query: SearchQuery, in vault: Vault, maxResults: Int) async -> [SearchResult] {
        let startTime = Date()
        var results: [SearchResult] = []
        
        // Build index if empty
        if searchIndex.isEmpty {
            await buildIndex(for: vault)
        }
        
        // Search through indexed notes
        for entry in searchIndex.values {
            var score = 0.0
            var matchedTerms: [String] = []
            
            // Check search terms
            for term in query.terms {
                let titleMatches = entry.title.localizedCaseInsensitiveContains(term)
                let contentMatches = entry.content.localizedCaseInsensitiveContains(term)
                
                if titleMatches {
                    score += 10.0 // Title matches are more important
                    matchedTerms.append(term)
                }
                if contentMatches {
                    score += 1.0
                    if !matchedTerms.contains(term) {
                        matchedTerms.append(term)
                    }
                }
            }
            
            // Check tag filters
            if !query.tags.isEmpty {
                let hasAllTags = query.tags.allSatisfy { entry.tags.contains($0) }
                if hasAllTags {
                    score += 5.0
                } else {
                    continue // Skip if required tags are missing
                }
            }
            
            // Check excluded tags
            if !query.excludedTags.isEmpty {
                let hasExcludedTag = query.excludedTags.contains { entry.tags.contains($0) }
                if hasExcludedTag {
                    continue // Skip if has excluded tag
                }
            }
            
            // Check excluded terms
            if !query.excludedTerms.isEmpty {
                let hasExcludedTerm = query.excludedTerms.contains { term in
                    entry.content.localizedCaseInsensitiveContains(term)
                }
                if hasExcludedTerm {
                    continue // Skip if has excluded term
                }
            }
            
            // Check path filters
            if !query.pathFilters.isEmpty {
                let matchesPath = query.pathFilters.contains { pathFilter in
                    entry.filePath.localizedCaseInsensitiveContains(pathFilter)
                }
                if !matchesPath {
                    continue // Skip if doesn't match path filter
                }
            }
            
            // Only include results with matches
            if score > 0 {
                let snippet = extractSnippet(from: entry.content, matching: query.terms.first ?? "")
                
                let result = SearchResult(
                    noteID: entry.noteID,
                    title: entry.title,
                    filePath: entry.filePath,
                    snippet: snippet,
                    relevanceScore: score,
                    matchedTerms: matchedTerms,
                    tags: entry.tags
                )
                
                results.append(result)
            }
        }
        
        // Sort by relevance score
        results.sort { $0.relevanceScore > $1.relevanceScore }
        
        // Limit results
        if results.count > maxResults {
            results = Array(results.prefix(maxResults))
        }
        
        // Publish stats
        let searchTime = Date().timeIntervalSince(startTime)
        let stats = SearchStats(
            totalResults: results.count,
            searchTime: searchTime,
            indexSize: searchIndex.count,
            lastIndexUpdate: lastIndexUpdate
        )
        searchStatsSubject.send(stats)
        
        return results
    }
    
    func quickSearch(_ text: String, in vault: Vault) async -> [SearchResult] {
        let query = SearchQuery(rawQuery: text)
        return await search(query, in: vault, maxResults: 50)
    }
    
    func buildIndex(for vault: Vault) async {
        searchIndex.removeAll()
        
        for note in vault.notes {
            let entry = SearchIndexEntry(note: note)
            searchIndex[note.id] = entry
        }
        
        lastIndexUpdate = Date()
    }
    
    func updateIndex(for note: Note, in vault: Vault) async {
        let entry = SearchIndexEntry(note: note)
        searchIndex[note.id] = entry
        lastIndexUpdate = Date()
    }
    
    func removeFromIndex(noteID: UUID, in vault: Vault) async {
        searchIndex.removeValue(forKey: noteID)
        lastIndexUpdate = Date()
    }
    
    func getSearchSuggestions(for partialQuery: String, in vault: Vault) -> [String] {
        var suggestions: Set<String> = []
        
        // Suggest note titles
        for entry in searchIndex.values {
            if entry.title.localizedCaseInsensitiveContains(partialQuery) {
                suggestions.insert(entry.title)
            }
        }
        
        // Suggest tags
        for entry in searchIndex.values {
            for tag in entry.tags {
                if tag.localizedCaseInsensitiveContains(partialQuery) {
                    suggestions.insert("#\(tag)")
                }
            }
        }
        
        return Array(suggestions).sorted().prefix(10).map { String($0) }
    }
    
    func getSearchStats(for vault: Vault) -> SearchStats {
        return SearchStats(
            totalResults: 0,
            searchTime: 0,
            indexSize: searchIndex.count,
            lastIndexUpdate: lastIndexUpdate
        )
    }
    
    // MARK: - Private Methods
    
    private func extractSnippet(from content: String, matching term: String, snippetLength: Int = 150) -> String {
        guard !term.isEmpty else {
            return String(content.prefix(snippetLength))
        }
        
        let lowercasedContent = content.lowercased()
        let lowercasedTerm = term.lowercased()
        
        if let range = lowercasedContent.range(of: lowercasedTerm) {
            let startIndex = content.index(range.lowerBound, offsetBy: -snippetLength / 2, limitedBy: content.startIndex) ?? content.startIndex
            let endIndex = content.index(range.upperBound, offsetBy: snippetLength / 2, limitedBy: content.endIndex) ?? content.endIndex
            
            var snippet = String(content[startIndex..<endIndex])
            
            if startIndex != content.startIndex {
                snippet = "..." + snippet
            }
            if endIndex != content.endIndex {
                snippet = snippet + "..."
            }
            
            return snippet
        }
        
        return String(content.prefix(snippetLength))
    }
}

/// Concrete implementation of TagManagerProtocol
@MainActor
class TagManager: TagManagerProtocol, ObservableObject {
    private let tagsDidChangeSubject = PassthroughSubject<[String: Int], Never>()
    var tagsDidChange: AnyPublisher<[String: Int], Never> {
        tagsDidChangeSubject.eraseToAnyPublisher()
    }
    
    private var tagIndex: [String: Set<UUID>] = [:]
    
    func getAllTags(in vault: Vault) -> [String: Int] {
        var tagCounts: [String: Int] = [:]
        
        for note in vault.notes {
            for tag in note.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
    }
    
    func getNotesWithTag(_ tag: String, in vault: Vault) -> [Note] {
        return vault.notes.filter { $0.tags.contains(tag) }
    }
    
    func updateTagIndex(for note: Note, in vault: Vault) async {
        // Remove note from all tag sets
        for (tag, noteIDs) in tagIndex {
            var updatedIDs = noteIDs
            updatedIDs.remove(note.id)
            tagIndex[tag] = updatedIDs
        }
        
        // Add note to new tag sets
        for tag in note.tags {
            tagIndex[tag, default: []].insert(note.id)
        }
        
        let tagCounts = getAllTags(in: vault)
        tagsDidChangeSubject.send(tagCounts)
    }
    
    func removeTagsForNote(_ noteID: UUID, in vault: Vault) async {
        for (tag, noteIDs) in tagIndex {
            var updatedIDs = noteIDs
            updatedIDs.remove(noteID)
            tagIndex[tag] = updatedIDs
        }
        
        let tagCounts = getAllTags(in: vault)
        tagsDidChangeSubject.send(tagCounts)
    }
    
    func getTagSuggestions(for partialTag: String, in vault: Vault) -> [String] {
        let allTags = getAllTags(in: vault)
        let matchingTags = allTags.keys.filter { $0.localizedCaseInsensitiveContains(partialTag) }
        return Array(matchingTags).sorted().prefix(10).map { String($0) }
    }
    
    func renameTag(from oldTag: String, to newTag: String, in vault: Vault) async throws -> [Note] {
        var updatedNotes: [Note] = []
        
        for note in vault.notes where note.tags.contains(oldTag) {
            var content = note.content
            
            // Replace #oldTag with #newTag
            let pattern = "#\(NSRegularExpression.escapedPattern(for: oldTag))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = content as NSString
                let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
                
                // Replace in reverse order
                for match in matches.reversed() {
                    if let swiftRange = Range(match.range, in: content) {
                        content.replaceSubrange(swiftRange, with: "#\(newTag)")
                    }
                }
                
                let updatedNote = Note(filePath: note.filePath, title: note.title, content: content)
                updatedNotes.append(updatedNote)
            }
        }
        
        return updatedNotes
    }
    
    func rebuildTagIndex(for vault: Vault) async {
        tagIndex.removeAll()
        
        for note in vault.notes {
            for tag in note.tags {
                tagIndex[tag, default: []].insert(note.id)
            }
        }
        
        let tagCounts = getAllTags(in: vault)
        tagsDidChangeSubject.send(tagCounts)
    }
}
