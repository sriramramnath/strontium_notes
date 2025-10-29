//
//  Folder.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

/// Represents a folder in the vault hierarchy
struct Folder: Identifiable, Codable {
    let id: UUID
    let name: String
    let path: String
    let parentID: UUID?
    var subfolders: [Folder]
    var notes: [Note]
    let createdDate: Date
    var modifiedDate: Date
    
    /// Computed property for the folder's full URL
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    /// Computed property to check if this is a root folder
    var isRoot: Bool {
        parentID == nil
    }
    
    /// Computed property for the folder's depth in the hierarchy
    var depth: Int {
        path.components(separatedBy: "/").count - 1
    }
    
    init(name: String, path: String, parentID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.parentID = parentID
        self.subfolders = []
        self.notes = []
        self.createdDate = Date()
        self.modifiedDate = Date()
    }
    
    /// Add a subfolder to this folder
    mutating func addSubfolder(_ folder: Folder) {
        subfolders.append(folder)
        modifiedDate = Date()
    }
    
    /// Remove a subfolder from this folder
    mutating func removeSubfolder(withID id: UUID) {
        subfolders.removeAll { $0.id == id }
        modifiedDate = Date()
    }
    
    /// Add a note to this folder
    mutating func addNote(_ note: Note) {
        notes.append(note)
        modifiedDate = Date()
    }
    
    /// Remove a note from this folder
    mutating func removeNote(withID id: UUID) {
        notes.removeAll { $0.id == id }
        modifiedDate = Date()
    }
    
    /// Get all notes recursively from this folder and its subfolders
    func getAllNotesRecursively() -> [Note] {
        var allNotes = notes
        for subfolder in subfolders {
            allNotes.append(contentsOf: subfolder.getAllNotesRecursively())
        }
        return allNotes
    }
    
    /// Get all subfolders recursively
    func getAllSubfoldersRecursively() -> [Folder] {
        var allFolders = subfolders
        for subfolder in subfolders {
            allFolders.append(contentsOf: subfolder.getAllSubfoldersRecursively())
        }
        return allFolders
    }
}