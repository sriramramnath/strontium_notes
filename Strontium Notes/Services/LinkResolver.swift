//
//  LinkResolver.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Concrete implementation of LinkResolverProtocol
@MainActor
class LinkResolver: LinkResolverProtocol, ObservableObject {
    private let linksDidChangeSubject = PassthroughSubject<[WikiLink], Never>()
    var linksDidChange: AnyPublisher<[WikiLink], Never> {
        linksDidChangeSubject.eraseToAnyPublisher()
    }
    
    private var linkCache: [UUID: [WikiLink]] = [:]
    
    func parseWikiLinks(from content: String, sourceNoteID: UUID) -> [WikiLink] {
        var links: [WikiLink] = []
        
        // Pattern for [[Note Name]] or [[Note Name|Display Text]]
        let pattern = #"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return links
        }
        
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let targetRange = match.range(at: 1)
            let displayRange = match.range(at: 2)
            
            guard targetRange.location != NSNotFound else { continue }
            
            let targetName = nsString.substring(with: targetRange)
            let displayText: String
            
            if displayRange.location != NSNotFound {
                displayText = nsString.substring(with: displayRange)
            } else {
                displayText = targetName
            }
            
            let link = WikiLink(
                sourceNoteID: sourceNoteID,
                targetNoteName: targetName,
                linkText: displayText,
                range: match.range
            )
            
            links.append(link)
        }
        
        return links
    }
    
    func resolveLinks(_ links: [WikiLink], in vault: Vault) async -> [WikiLink] {
        var resolvedLinks: [WikiLink] = []
        
        for link in links {
            // Try to find the target note by title
            if let targetNote = vault.notes.first(where: { $0.title == link.targetNoteName }) {
                let resolvedLink = WikiLink(
                    sourceNoteID: link.sourceNoteID,
                    targetNoteName: link.targetNoteName,
                    linkText: link.linkText,
                    range: link.range,
                    resolvedTargetID: targetNote.id
                )
                resolvedLinks.append(resolvedLink)
            } else {
                // Link is broken
                resolvedLinks.append(link)
            }
        }
        
        return resolvedLinks
    }
    
    func updateLinksForRenamedNote(oldTitle: String, newTitle: String, in vault: Vault) async throws -> [Note] {
        var updatedNotes: [Note] = []
        
        for note in vault.notes {
            var content = note.content
            var hasChanges = false
            
            // Replace all occurrences of [[oldTitle]] with [[newTitle]]
            let patterns = [
                "\\[\\[\(NSRegularExpression.escapedPattern(for: oldTitle))\\]\\]",
                "\\[\\[\(NSRegularExpression.escapedPattern(for: oldTitle))\\|([^\\]]+)\\]\\]"
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let nsString = content as NSString
                    let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
                    
                    if !matches.isEmpty {
                        hasChanges = true
                        
                        // Replace in reverse order to maintain ranges
                        for match in matches.reversed() {
                            let range = match.range
                            let oldText = nsString.substring(with: range)
                            
                            let newText: String
                            if match.numberOfRanges > 1 {
                                // Has display text
                                let displayRange = match.range(at: 1)
                                let displayText = nsString.substring(with: displayRange)
                                newText = "[[\(newTitle)|\(displayText)]]"
                            } else {
                                newText = "[[\(newTitle)]]"
                            }
                            
                            if let swiftRange = Range(range, in: content) {
                                content.replaceSubrange(swiftRange, with: newText)
                            }
                        }
                    }
                }
            }
            
            if hasChanges {
                let updatedNote = Note(filePath: note.filePath, title: note.title, content: content)
                updatedNotes.append(updatedNote)
            }
        }
        
        return updatedNotes
    }
    
    func getLinksToNote(_ noteID: UUID, in vault: Vault) -> [WikiLink] {
        var linksToNote: [WikiLink] = []
        
        // Find the target note
        guard let targetNote = vault.notes.first(where: { $0.id == noteID }) else {
            return linksToNote
        }
        
        // Search all notes for links to this note
        for note in vault.notes where note.id != noteID {
            let links = parseWikiLinks(from: note.content, sourceNoteID: note.id)
            let matchingLinks = links.filter { $0.targetNoteName == targetNote.title }
            linksToNote.append(contentsOf: matchingLinks)
        }
        
        return linksToNote
    }
    
    func getLinksFromNote(_ noteID: UUID, in vault: Vault) -> [WikiLink] {
        guard let note = vault.notes.first(where: { $0.id == noteID }) else {
            return []
        }
        
        return parseWikiLinks(from: note.content, sourceNoteID: noteID)
    }
    
    func validateLinks(in vault: Vault) async -> [WikiLink] {
        var brokenLinks: [WikiLink] = []
        
        for note in vault.notes {
            let links = parseWikiLinks(from: note.content, sourceNoteID: note.id)
            
            for link in links {
                // Check if target note exists
                let targetExists = vault.notes.contains { $0.title == link.targetNoteName }
                if !targetExists {
                    brokenLinks.append(link)
                }
            }
        }
        
        return brokenLinks
    }
}

/// Concrete implementation of BacklinkManagerProtocol
@MainActor
class BacklinkManager: BacklinkManagerProtocol, ObservableObject {
    private let backlinksDidChangeSubject = PassthroughSubject<[Backlink], Never>()
    var backlinksDidChange: AnyPublisher<[Backlink], Never> {
        backlinksDidChangeSubject.eraseToAnyPublisher()
    }
    
    private let linkResolver: LinkResolver
    private var backlinkCache: [UUID: [Backlink]] = [:]
    
    init(linkResolver: LinkResolver) {
        self.linkResolver = linkResolver
    }
    
    func getBacklinks(for noteID: UUID, in vault: Vault) -> [Backlink] {
        // Check cache first
        if let cached = backlinkCache[noteID] {
            return cached
        }
        
        var backlinks: [Backlink] = []
        
        guard let targetNote = vault.notes.first(where: { $0.id == noteID }) else {
            return backlinks
        }
        
        // Find all notes that link to this note
        for sourceNote in vault.notes where sourceNote.id != noteID {
            let links = linkResolver.parseWikiLinks(from: sourceNote.content, sourceNoteID: sourceNote.id)
            
            for link in links where link.targetNoteName == targetNote.title {
                // Extract context snippet
                let snippet = extractContextSnippet(from: sourceNote.content, around: link.range)
                
                let backlink = Backlink(
                    sourceNoteID: sourceNote.id,
                    sourceNoteTitle: sourceNote.title,
                    targetNoteID: noteID,
                    linkText: link.linkText,
                    contextSnippet: snippet
                )
                
                backlinks.append(backlink)
            }
        }
        
        backlinkCache[noteID] = backlinks
        return backlinks
    }
    
    func updateBacklinks(for note: Note, in vault: Vault) async {
        // Invalidate cache for this note
        backlinkCache.removeValue(forKey: note.id)
        
        // Rebuild backlinks
        let backlinks = getBacklinks(for: note.id, in: vault)
        backlinksDidChangeSubject.send(backlinks)
    }
    
    func findUnlinkedMentions(of noteTitle: String, targetNoteID: UUID, in vault: Vault) async -> [UnlinkedMention] {
        var mentions: [UnlinkedMention] = []
        
        for sourceNote in vault.notes where sourceNote.id != targetNoteID {
            // Find all occurrences of the note title that are NOT in wikilinks
            let content = sourceNote.content
            let nsString = content as NSString
            
            // Get all wikilink ranges to exclude
            let links = linkResolver.parseWikiLinks(from: content, sourceNoteID: sourceNote.id)
            let linkRanges = links.map { $0.range }
            
            // Search for the note title
            var searchRange = NSRange(location: 0, length: nsString.length)
            
            while searchRange.location < nsString.length {
                let foundRange = nsString.range(of: noteTitle, options: [.caseInsensitive], range: searchRange)
                
                if foundRange.location == NSNotFound {
                    break
                }
                
                // Check if this occurrence is inside a wikilink
                let isInLink = linkRanges.contains { NSIntersectionRange($0, foundRange).length > 0 }
                
                if !isInLink {
                    let snippet = extractContextSnippet(from: content, around: foundRange)
                    
                    let mention = UnlinkedMention(
                        sourceNoteID: sourceNote.id,
                        targetNoteID: targetNoteID,
                        mentionText: noteTitle,
                        contextSnippet: snippet,
                        range: foundRange,
                        confidence: 0.8
                    )
                    
                    mentions.append(mention)
                }
                
                // Move search range forward
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = nsString.length - searchRange.location
            }
        }
        
        return mentions
    }
    
    func convertMentionToLink(_ mention: UnlinkedMention, in vault: Vault) async throws -> Note {
        guard let sourceNote = vault.notes.first(where: { $0.id == mention.sourceNoteID }) else {
            throw NoteError.fileNotFound
        }
        
        var content = sourceNote.content
        let nsString = content as NSString
        
        // Replace the mention with a wikilink
        let mentionText = nsString.substring(with: mention.range)
        let wikilink = "[[\(mentionText)]]"
        
        if let swiftRange = Range(mention.range, in: content) {
            content.replaceSubrange(swiftRange, with: wikilink)
        }
        
        return Note(filePath: sourceNote.filePath, title: sourceNote.title, content: content)
    }
    
    func rebuildBacklinkIndex(for vault: Vault) async {
        backlinkCache.removeAll()
        
        // Rebuild cache for all notes
        for note in vault.notes {
            _ = getBacklinks(for: note.id, in: vault)
        }
    }
    
    // MARK: - Private Methods
    
    private func extractContextSnippet(from content: String, around range: NSRange, contextLength: Int = 100) -> String {
        let nsString = content as NSString
        
        let start = max(0, range.location - contextLength)
        let end = min(nsString.length, range.location + range.length + contextLength)
        let snippetRange = NSRange(location: start, length: end - start)
        
        var snippet = nsString.substring(with: snippetRange)
        
        // Add ellipsis if truncated
        if start > 0 {
            snippet = "..." + snippet
        }
        if end < nsString.length {
            snippet = snippet + "..."
        }
        
        return snippet
    }
}
