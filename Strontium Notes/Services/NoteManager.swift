//
//  NoteManager.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Concrete implementation of NoteManagerProtocol
@MainActor
class NoteManager: NoteManagerProtocol, ObservableObject {
    private let noteDidChangeSubject = PassthroughSubject<Note, Never>()
    var noteDidChange: AnyPublisher<Note, Never> {
        noteDidChangeSubject.eraseToAnyPublisher()
    }
    
    private let noteDidDeleteSubject = PassthroughSubject<UUID, Never>()
    var noteDidDelete: AnyPublisher<UUID, Never> {
        noteDidDeleteSubject.eraseToAnyPublisher()
    }
    
    private let fileManager = FileManager.default
    
    func createNote(title: String, content: String, in vault: Vault, folderPath: String?) async throws -> Note {
        let fileName = generateUniqueFileName(for: title, in: vault, folderPath: folderPath)
        let fullPath: String
        
        if let folderPath = folderPath {
            fullPath = "\(folderPath)/\(fileName)"
        } else {
            fullPath = fileName
        }
        
        let fileURL = vault.rootURL.appendingPathComponent(fullPath)
        
        // Create directory if needed
        let directory = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        // Write content to file
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Create note object
        let note = Note(filePath: fullPath, title: title, content: content)
        noteDidChangeSubject.send(note)
        
        return note
    }
    
    func loadNote(from filePath: String) async throws -> Note {
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard fileManager.fileExists(atPath: filePath) else {
            throw NoteError.fileNotFound
        }
        
        guard fileManager.isReadableFile(atPath: filePath) else {
            throw NoteError.permissionDenied
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let title = fileURL.deletingPathExtension().lastPathComponent
            
            // Parse frontmatter
            let (frontmatter, bodyContent) = parseFrontmatter(from: content)
            
            return Note(filePath: filePath, title: title, content: bodyContent, frontmatter: frontmatter)
        } catch {
            throw NoteError.corruptedFile
        }
    }
    
    func saveNote(_ note: Note) async throws {
        let fileURL = URL(fileURLWithPath: note.filePath)
        
        guard fileManager.isWritableFile(atPath: fileURL.deletingLastPathComponent().path) else {
            throw NoteError.permissionDenied
        }
        
        // Check disk space (simplified check)
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: fileURL.path),
           let freeSize = attributes[.systemFreeSize] as? Int64,
           freeSize < 1024 * 1024 { // Less than 1MB
            throw NoteError.diskSpaceInsufficient
        }
        
        do {
            try note.content.write(to: fileURL, atomically: true, encoding: .utf8)
            noteDidChangeSubject.send(note)
        } catch {
            throw NoteError.permissionDenied
        }
    }
    
    func updateNote(_ note: Note, with newContent: String) async throws -> Note {
        let fileURL = URL(fileURLWithPath: note.filePath)
        
        try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        let updatedNote = Note(filePath: note.filePath, title: note.title, content: newContent)
        noteDidChangeSubject.send(updatedNote)
        
        return updatedNote
    }
    
    func renameNote(_ note: Note, to newTitle: String) async throws -> Note {
        // filePath is relative to vault root
        // Extract directory path
        let pathComponents = note.filePath.components(separatedBy: "/")
        var directoryComponents = pathComponents
        directoryComponents.removeLast() // Remove old filename
        
        let newFileName = sanitizeFileName(newTitle) + ".md"
        let newRelativePath: String
        
        if directoryComponents.isEmpty {
            newRelativePath = newFileName
        } else {
            newRelativePath = directoryComponents.joined(separator: "/") + "/" + newFileName
        }
        
        // Create updated note with new relative path
        let updatedNote = Note(filePath: newRelativePath, title: newTitle, content: note.content)
        noteDidChangeSubject.send(updatedNote)
        
        return updatedNote
    }
    
    func deleteNote(_ note: Note) async throws {
        let fileURL = URL(fileURLWithPath: note.filePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw NoteError.fileNotFound
        }
        
        try fileManager.removeItem(at: fileURL)
        noteDidDeleteSubject.send(note.id)
    }
    
    func moveNote(_ note: Note, to destinationPath: String) async throws -> Note {
        let oldURL = URL(fileURLWithPath: note.filePath)
        let fileName = oldURL.lastPathComponent
        let newPath = "\(destinationPath)/\(fileName)"
        let newURL = URL(fileURLWithPath: newPath)
        
        // Create destination directory if needed
        let directory = newURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        try fileManager.moveItem(at: oldURL, to: newURL)
        
        let movedNote = Note(filePath: newPath, title: note.title, content: note.content)
        noteDidChangeSubject.send(movedNote)
        
        return movedNote
    }
    
    func getAllNotes(in vault: Vault) async throws -> [Note] {
        var notes: [Note] = []
        let enumerator = fileManager.enumerator(at: vault.rootURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "md" {
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    let title = fileURL.deletingPathExtension().lastPathComponent
                    let relativePath = fileURL.path.replacingOccurrences(of: vault.rootURL.path + "/", with: "")
                    let note = Note(filePath: relativePath, title: title, content: content)
                    notes.append(note)
                } catch {
                    continue
                }
            }
        }
        
        return notes
    }
    
    func parseFrontmatter(from content: String) -> ([String: Any], String) {
        let lines = content.components(separatedBy: .newlines)
        
        // Check if content starts with frontmatter delimiter
        guard lines.first == "---" else {
            return ([:], content)
        }
        
        // Find the closing delimiter
        var frontmatterLines: [String] = []
        var endIndex = 1
        
        for i in 1..<lines.count {
            if lines[i] == "---" {
                endIndex = i
                break
            }
            frontmatterLines.append(lines[i])
        }
        
        // Parse YAML-like frontmatter (simplified)
        var frontmatter: [String: Any] = [:]
        for line in frontmatterLines {
            let parts = line.components(separatedBy: ": ")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                frontmatter[key] = value
            }
        }
        
        // Get remaining content
        let bodyLines = Array(lines[(endIndex + 1)...])
        let bodyContent = bodyLines.joined(separator: "\n")
        
        return (frontmatter, bodyContent)
    }
    
    func generateUniqueFileName(for title: String, in vault: Vault, folderPath: String?) -> String {
        let sanitized = sanitizeFileName(title)
        var fileName = "\(sanitized).md"
        var counter = 1
        
        let basePath = folderPath ?? ""
        let fullPath = basePath.isEmpty ? fileName : "\(basePath)/\(fileName)"
        var fileURL = vault.rootURL.appendingPathComponent(fullPath)
        
        while fileManager.fileExists(atPath: fileURL.path) {
            fileName = "\(sanitized) \(counter).md"
            let newFullPath = basePath.isEmpty ? fileName : "\(basePath)/\(fileName)"
            fileURL = vault.rootURL.appendingPathComponent(newFullPath)
            counter += 1
        }
        
        return fileName
    }
    
    // MARK: - Private Methods
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "-")
    }
}
