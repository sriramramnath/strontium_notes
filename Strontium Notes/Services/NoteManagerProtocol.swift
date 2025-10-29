//
//  NoteManagerProtocol.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation
import Combine

/// Protocol defining the note management interface
protocol NoteManagerProtocol: ObservableObject {
    /// Publisher for note changes
    var noteDidChange: AnyPublisher<Note, Never> { get }
    
    /// Publisher for note deletion
    var noteDidDelete: AnyPublisher<UUID, Never> { get }
    
    /// Create a new note in the specified vault
    /// - Parameters:
    ///   - title: The title of the new note
    ///   - content: The initial content of the note
    ///   - vault: The vault where the note should be created
    ///   - folderPath: Optional folder path within the vault
    /// - Returns: The newly created note
    /// - Throws: NoteError if the note cannot be created
    func createNote(title: String, content: String, in vault: Vault, folderPath: String?) async throws -> Note
    
    /// Load a note from the file system
    /// - Parameter filePath: The file path of the note to load
    /// - Returns: The loaded note
    /// - Throws: NoteError if the note cannot be loaded
    func loadNote(from filePath: String) async throws -> Note
    
    /// Save a note to the file system
    /// - Parameter note: The note to save
    /// - Throws: NoteError if the note cannot be saved
    func saveNote(_ note: Note) async throws
    
    /// Update an existing note
    /// - Parameters:
    ///   - note: The note to update
    ///   - newContent: The new content for the note
    /// - Returns: The updated note
    /// - Throws: NoteError if the note cannot be updated
    func updateNote(_ note: Note, with newContent: String) async throws -> Note
    
    /// Rename a note
    /// - Parameters:
    ///   - note: The note to rename
    ///   - newTitle: The new title for the note
    /// - Returns: The renamed note
    /// - Throws: NoteError if the note cannot be renamed
    func renameNote(_ note: Note, to newTitle: String) async throws -> Note
    
    /// Delete a note
    /// - Parameter note: The note to delete
    /// - Throws: NoteError if the note cannot be deleted
    func deleteNote(_ note: Note) async throws
    
    /// Move a note to a different folder
    /// - Parameters:
    ///   - note: The note to move
    ///   - destinationPath: The destination folder path
    /// - Returns: The moved note
    /// - Throws: NoteError if the note cannot be moved
    func moveNote(_ note: Note, to destinationPath: String) async throws -> Note
    
    /// Get all notes in a vault
    /// - Parameter vault: The vault to scan for notes
    /// - Returns: Array of all notes in the vault
    func getAllNotes(in vault: Vault) async throws -> [Note]
    
    /// Parse frontmatter from note content
    /// - Parameter content: The note content to parse
    /// - Returns: Tuple containing frontmatter dictionary and remaining content
    func parseFrontmatter(from content: String) -> ([String: Any], String)
    
    /// Generate a unique file name for a note
    /// - Parameters:
    ///   - title: The desired note title
    ///   - vault: The vault where the note will be created
    ///   - folderPath: Optional folder path within the vault
    /// - Returns: A unique file name
    func generateUniqueFileName(for title: String, in vault: Vault, folderPath: String?) -> String
}

/// Errors that can occur during note operations
enum NoteError: LocalizedError {
    case fileNotFound
    case permissionDenied
    case invalidContent
    case duplicateTitle
    case corruptedFile
    case diskSpaceInsufficient
    case invalidFileName
    case frontmatterParsingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The note file could not be found."
        case .permissionDenied:
            return "Permission denied. Cannot access the note file."
        case .invalidContent:
            return "The note content is invalid or corrupted."
        case .duplicateTitle:
            return "A note with this title already exists."
        case .corruptedFile:
            return "The note file is corrupted and cannot be read."
        case .diskSpaceInsufficient:
            return "Insufficient disk space to save the note."
        case .invalidFileName:
            return "The note title contains invalid characters."
        case .frontmatterParsingFailed:
            return "Failed to parse the note's frontmatter."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Check if the file has been moved or deleted."
        case .permissionDenied:
            return "Check file permissions and try again."
        case .invalidContent:
            return "Try opening the file in a text editor to check its content."
        case .duplicateTitle:
            return "Choose a different title for the note."
        case .corruptedFile:
            return "Try restoring from a backup if available."
        case .diskSpaceInsufficient:
            return "Free up disk space and try again."
        case .invalidFileName:
            return "Remove special characters from the note title."
        case .frontmatterParsingFailed:
            return "Check the YAML syntax in the note's frontmatter."
        }
    }
}