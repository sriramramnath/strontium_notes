//
//  LinkResolverProtocol.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation
import Combine

/// Protocol defining the link resolution interface
protocol LinkResolverProtocol: ObservableObject {
    /// Publisher for link changes
    var linksDidChange: AnyPublisher<[WikiLink], Never> { get }
    
    /// Parse wikilinks from note content
    /// - Parameters:
    ///   - content: The note content to parse
    ///   - sourceNoteID: The ID of the note containing the links
    /// - Returns: Array of parsed wikilinks
    func parseWikiLinks(from content: String, sourceNoteID: UUID) -> [WikiLink]
    
    /// Resolve wikilinks to actual notes in the vault
    /// - Parameters:
    ///   - links: The wikilinks to resolve
    ///   - vault: The vault containing the notes
    /// - Returns: Array of resolved wikilinks
    func resolveLinks(_ links: [WikiLink], in vault: Vault) async -> [WikiLink]
    
    /// Update links when a note is renamed
    /// - Parameters:
    ///   - oldTitle: The old note title
    ///   - newTitle: The new note title
    ///   - vault: The vault containing the notes
    /// - Returns: Array of updated notes that contained links to the renamed note
    func updateLinksForRenamedNote(oldTitle: String, newTitle: String, in vault: Vault) async throws -> [Note]
    
    /// Get all links pointing to a specific note
    /// - Parameters:
    ///   - noteID: The ID of the target note
    ///   - vault: The vault to search in
    /// - Returns: Array of wikilinks pointing to the note
    func getLinksToNote(_ noteID: UUID, in vault: Vault) -> [WikiLink]
    
    /// Get all links from a specific note
    /// - Parameters:
    ///   - noteID: The ID of the source note
    ///   - vault: The vault to search in
    /// - Returns: Array of wikilinks from the note
    func getLinksFromNote(_ noteID: UUID, in vault: Vault) -> [WikiLink]
    
    /// Validate that all links in a vault are properly resolved
    /// - Parameter vault: The vault to validate
    /// - Returns: Array of broken links
    func validateLinks(in vault: Vault) async -> [WikiLink]
}

/// Protocol defining the backlink management interface
protocol BacklinkManagerProtocol: ObservableObject {
    /// Publisher for backlink changes
    var backlinksDidChange: AnyPublisher<[Backlink], Never> { get }
    
    /// Get all backlinks for a specific note
    /// - Parameters:
    ///   - noteID: The ID of the target note
    ///   - vault: The vault to search in
    /// - Returns: Array of backlinks to the note
    func getBacklinks(for noteID: UUID, in vault: Vault) -> [Backlink]
    
    /// Update backlinks when note content changes
    /// - Parameters:
    ///   - note: The note that was updated
    ///   - vault: The vault containing the note
    func updateBacklinks(for note: Note, in vault: Vault) async
    
    /// Find unlinked mentions of a note title in other notes
    /// - Parameters:
    ///   - noteTitle: The title to search for
    ///   - targetNoteID: The ID of the note being mentioned
    ///   - vault: The vault to search in
    /// - Returns: Array of unlinked mentions
    func findUnlinkedMentions(of noteTitle: String, targetNoteID: UUID, in vault: Vault) async -> [UnlinkedMention]
    
    /// Convert an unlinked mention to a wikilink
    /// - Parameters:
    ///   - mention: The unlinked mention to convert
    ///   - vault: The vault containing the notes
    /// - Returns: The updated source note with the new link
    func convertMentionToLink(_ mention: UnlinkedMention, in vault: Vault) async throws -> Note
    
    /// Rebuild the entire backlink index for a vault
    /// - Parameter vault: The vault to rebuild the index for
    func rebuildBacklinkIndex(for vault: Vault) async
}