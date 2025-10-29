//
//  Vault.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

/// Represents a vault - a local folder containing markdown files and associated assets
struct Vault: Identifiable, Codable {
    let id: UUID
    let name: String
    let rootURL: URL
    let settings: VaultSettings
    var notes: [Note]
    var folders: [Folder]
    let createdDate: Date
    var lastAccessedDate: Date
    
    init(name: String, rootURL: URL, settings: VaultSettings = VaultSettings()) {
        self.id = UUID()
        self.name = name
        self.rootURL = rootURL
        self.settings = settings
        self.notes = []
        self.folders = []
        self.createdDate = Date()
        self.lastAccessedDate = Date()
    }
}

/// Configuration settings for a vault
struct VaultSettings: Codable {
    var defaultNoteTemplate: String
    var attachmentsFolderName: String
    var enableAutoSave: Bool
    var autoSaveInterval: TimeInterval
    var enableFileWatcher: Bool
    var maxSearchResults: Int
    var enableLaTeX: Bool
    var theme: String
    
    init() {
        self.defaultNoteTemplate = ""
        self.attachmentsFolderName = "attachments"
        self.enableAutoSave = true
        self.autoSaveInterval = 30.0
        self.enableFileWatcher = true
        self.maxSearchResults = 100
        self.enableLaTeX = true
        self.theme = "default"
    }
}

/// Reference to a vault for recent vaults tracking
struct VaultReference: Identifiable, Codable {
    let id: UUID
    let name: String
    let path: String
    let lastAccessedDate: Date
    
    init(vault: Vault) {
        self.id = vault.id
        self.name = vault.name
        self.path = vault.rootURL.path
        self.lastAccessedDate = vault.lastAccessedDate
    }
}