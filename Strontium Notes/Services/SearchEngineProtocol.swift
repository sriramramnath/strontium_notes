//
//  SearchEngineProtocol.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation
import Combine

/// Protocol defining the search engine interface
protocol SearchEngineProtocol: ObservableObject {
    /// Publisher for search results
    var searchResults: AnyPublisher<[SearchResult], Never> { get }
    
    /// Publisher for search statistics
    var searchStats: AnyPublisher<SearchStats, Never> { get }
    
    /// Perform a full-text search across the vault
    /// - Parameters:
    ///   - query: The search query to execute
    ///   - vault: The vault to search in
    ///   - maxResults: Maximum number of results to return
    /// - Returns: Array of search results sorted by relevance
    func search(_ query: SearchQuery, in vault: Vault, maxResults: Int) async -> [SearchResult]
    
    /// Perform a quick search with simple text matching
    /// - Parameters:
    ///   - text: The text to search for
    ///   - vault: The vault to search in
    /// - Returns: Array of search results
    func quickSearch(_ text: String, in vault: Vault) async -> [SearchResult]
    
    /// Build or update the search index for a vault
    /// - Parameter vault: The vault to index
    func buildIndex(for vault: Vault) async
    
    /// Update the search index for a specific note
    /// - Parameters:
    ///   - note: The note to update in the index
    ///   - vault: The vault containing the note
    func updateIndex(for note: Note, in vault: Vault) async
    
    /// Remove a note from the search index
    /// - Parameters:
    ///   - noteID: The ID of the note to remove
    ///   - vault: The vault containing the note
    func removeFromIndex(noteID: UUID, in vault: Vault) async
    
    /// Get search suggestions based on partial input
    /// - Parameters:
    ///   - partialQuery: The partial search query
    ///   - vault: The vault to search in
    /// - Returns: Array of suggested search terms
    func getSearchSuggestions(for partialQuery: String, in vault: Vault) -> [String]
    
    /// Get search statistics for the current index
    /// - Parameter vault: The vault to get statistics for
    /// - Returns: Search statistics
    func getSearchStats(for vault: Vault) -> SearchStats
}

/// Protocol defining the tag management interface
protocol TagManagerProtocol: ObservableObject {
    /// Publisher for tag changes
    var tagsDidChange: AnyPublisher<[String: Int], Never> { get }
    
    /// Get all tags used in the vault with their usage counts
    /// - Parameter vault: The vault to analyze
    /// - Returns: Dictionary mapping tag names to usage counts
    func getAllTags(in vault: Vault) -> [String: Int]
    
    /// Get notes that contain a specific tag
    /// - Parameters:
    ///   - tag: The tag to search for
    ///   - vault: The vault to search in
    /// - Returns: Array of notes containing the tag
    func getNotesWithTag(_ tag: String, in vault: Vault) -> [Note]
    
    /// Update tag index when a note is modified
    /// - Parameters:
    ///   - note: The note that was updated
    ///   - vault: The vault containing the note
    func updateTagIndex(for note: Note, in vault: Vault) async
    
    /// Remove tags for a deleted note
    /// - Parameters:
    ///   - noteID: The ID of the deleted note
    ///   - vault: The vault that contained the note
    func removeTagsForNote(_ noteID: UUID, in vault: Vault) async
    
    /// Get tag suggestions based on partial input
    /// - Parameters:
    ///   - partialTag: The partial tag name
    ///   - vault: The vault to search in
    /// - Returns: Array of suggested tag names
    func getTagSuggestions(for partialTag: String, in vault: Vault) -> [String]
    
    /// Rename a tag across all notes in the vault
    /// - Parameters:
    ///   - oldTag: The current tag name
    ///   - newTag: The new tag name
    ///   - vault: The vault containing the notes
    /// - Returns: Array of updated notes
    func renameTag(from oldTag: String, to newTag: String, in vault: Vault) async throws -> [Note]
    
    /// Rebuild the tag index for a vault
    /// - Parameter vault: The vault to rebuild the index for
    func rebuildTagIndex(for vault: Vault) async
}