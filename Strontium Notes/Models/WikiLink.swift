//
//  WikiLink.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

/// Represents a wikilink relationship between notes
struct WikiLink: Identifiable, Codable {
    let id: UUID
    let sourceNoteID: UUID
    let targetNoteName: String
    let resolvedTargetID: UUID?
    let linkText: String
    let range: NSRange
    let createdDate: Date
    
    /// Computed property to check if the link is resolved
    var isResolved: Bool {
        resolvedTargetID != nil
    }
    
    /// Computed property to check if this is a broken link
    var isBroken: Bool {
        !isResolved
    }
    
    init(sourceNoteID: UUID, targetNoteName: String, linkText: String, range: NSRange, resolvedTargetID: UUID? = nil) {
        self.id = UUID()
        self.sourceNoteID = sourceNoteID
        self.targetNoteName = targetNoteName
        self.linkText = linkText
        self.range = range
        self.resolvedTargetID = resolvedTargetID
        self.createdDate = Date()
    }
}

/// Represents a backlink - a reference from another note to the current note
struct Backlink: Identifiable, Codable {
    let id: UUID
    let sourceNoteID: UUID
    let sourceNoteTitle: String
    let targetNoteID: UUID
    let linkText: String
    let contextSnippet: String
    let createdDate: Date
    
    init(sourceNoteID: UUID, sourceNoteTitle: String, targetNoteID: UUID, linkText: String, contextSnippet: String) {
        self.id = UUID()
        self.sourceNoteID = sourceNoteID
        self.sourceNoteTitle = sourceNoteTitle
        self.targetNoteID = targetNoteID
        self.linkText = linkText
        self.contextSnippet = contextSnippet
        self.createdDate = Date()
    }
}

/// Represents an unlinked mention - text that matches a note title but isn't linked
struct UnlinkedMention: Identifiable, Codable {
    let id: UUID
    let sourceNoteID: UUID
    let targetNoteID: UUID
    let mentionText: String
    let contextSnippet: String
    let range: NSRange
    let confidence: Double
    let createdDate: Date
    
    init(sourceNoteID: UUID, targetNoteID: UUID, mentionText: String, contextSnippet: String, range: NSRange, confidence: Double = 1.0) {
        self.id = UUID()
        self.sourceNoteID = sourceNoteID
        self.targetNoteID = targetNoteID
        self.mentionText = mentionText
        self.contextSnippet = contextSnippet
        self.range = range
        self.confidence = confidence
        self.createdDate = Date()
    }
}

// NSRange already conforms to Codable in Foundation, so no extension needed