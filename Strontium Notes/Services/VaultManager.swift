//
//  VaultManager.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Concrete implementation of VaultManagerProtocol
@MainActor
class VaultManager: VaultManagerProtocol, ObservableObject {
    @Published private(set) var currentVault: Vault?
    @Published private(set) var recentVaults: [VaultReference] = []
    
    private let vaultDidChangeSubject = PassthroughSubject<Vault?, Never>()
    var vaultDidChange: AnyPublisher<Vault?, Never> {
        vaultDidChangeSubject.eraseToAnyPublisher()
    }
    
    private let fileManager = FileManager.default
    private let recentVaultsKey = "com.strontium.recentVaults"
    private let fileSystemWatcher = FileSystemWatcher()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadRecentVaults()
        setupFileWatcher()
    }
    
    private func setupFileWatcher() {
        fileSystemWatcher.fileChanged
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    try? await self?.refreshCurrentVault()
                }
            }
            .store(in: &cancellables)
    }
    
    func openVault(at url: URL) async throws -> Vault {
        // Validate the vault location
        guard fileManager.fileExists(atPath: url.path) else {
            throw VaultError.directoryNotFound
        }
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw VaultError.invalidVaultStructure
        }
        
        // Permission check removed - file picker grants access automatically
        
        // Check if it's a network location
        if url.path.hasPrefix("/Volumes/") || url.path.contains("://") {
            throw VaultError.networkLocationNotSupported
        }
        
        // Create vault instance
        let vaultName = url.lastPathComponent
        var vault = Vault(name: vaultName, rootURL: url)
        
        // Scan the vault for notes and folders
        try await scanVault(&vault)
        
        // Update current vault
        currentVault = vault
        vaultDidChangeSubject.send(vault)
        
        // Add to recent vaults
        addToRecentVaults(vault)
        
        // Start watching for file changes
        if vault.settings.enableFileWatcher {
            fileSystemWatcher.startWatching(url: vault.rootURL)
        }
        
        return vault
    }
    
    func closeVault(_ vault: Vault) {
        if currentVault?.id == vault.id {
            fileSystemWatcher.stopWatching()
            currentVault = nil
            vaultDidChangeSubject.send(nil)
        }
    }
    
    func getCurrentVault() -> Vault? {
        return currentVault
    }
    
    func getRecentVaults() -> [VaultReference] {
        return recentVaults
    }
    
    func createVault(name: String, at url: URL) async throws -> Vault {
        let vaultURL = url.appendingPathComponent(name)
        
        // Check if directory already exists
        if fileManager.fileExists(atPath: vaultURL.path) {
            throw VaultError.vaultAlreadyOpen
        }
        
        // Create vault directory
        try fileManager.createDirectory(at: vaultURL, withIntermediateDirectories: true)
        
        // Create default folders
        let attachmentsURL = vaultURL.appendingPathComponent("attachments")
        try fileManager.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)
        
        // Create welcome note
        let welcomeNote = """
        # Welcome to \(name)
        
        This is your new vault. Start creating notes and organizing your knowledge!
        
        ## Getting Started
        - Create new notes with Cmd+N
        - Link notes using [[Note Name]] syntax
        - Add tags with #tag
        - Search with Cmd+F
        
        Happy note-taking! 📝
        """
        
        let welcomeURL = vaultURL.appendingPathComponent("Welcome.md")
        try welcomeNote.write(to: welcomeURL, atomically: true, encoding: .utf8)
        
        // Open the newly created vault
        return try await openVault(at: vaultURL)
    }
    
    func refreshCurrentVault() async throws {
        guard var vault = currentVault else { return }
        try await scanVault(&vault)
        currentVault = vault
        vaultDidChangeSubject.send(vault)
    }
    
    func isValidVault(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    // MARK: - Private Methods
    
    private func scanVault(_ vault: inout Vault) async throws {
        vault.notes = []
        vault.folders = []
        
        let rootURL = vault.rootURL
        let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey])
        
        var folderDict: [String: Folder] = [:]
        var notesList: [Note] = []
        var foldersWithMarkdown: Set<String> = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let relativePath = fileURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
            
            // Check if it's a directory
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if let isDirectory = resourceValues.isDirectory, isDirectory {
                let folderPath = relativePath
                let folderName = fileURL.lastPathComponent
                
                // Skip hidden folders, system folders, and common non-note folders
                if folderName.hasPrefix(".") || 
                   folderName == "attachments" ||
                   folderName == "node_modules" ||
                   folderName.hasSuffix(".xcodeproj") ||
                   folderName.hasSuffix(".xcassets") ||
                   folderName.hasSuffix(".xcworkspace") {
                    enumerator?.skipDescendants()
                    continue
                }
                
                let folder = Folder(name: folderName, path: folderPath)
                folderDict[folderPath] = folder
            } else if fileURL.pathExtension == "md" {
                // It's a markdown file
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    let title = fileURL.deletingPathExtension().lastPathComponent
                    let note = Note(filePath: relativePath, title: title, content: content)
                    notesList.append(note)
                    
                    // Mark parent folders as containing markdown
                    var pathComponents = relativePath.components(separatedBy: "/")
                    pathComponents.removeLast() // Remove filename
                    var currentPath = ""
                    for component in pathComponents {
                        currentPath = currentPath.isEmpty ? component : currentPath + "/" + component
                        foldersWithMarkdown.insert(currentPath)
                    }
                } catch {
                    // Skip files that can't be read
                    continue
                }
            }
        }
        
        // Only include folders that contain markdown files
        let filteredFolders = folderDict.values.filter { folder in
            foldersWithMarkdown.contains(folder.path)
        }
        
        vault.notes = notesList
        vault.folders = Array(filteredFolders)
    }
    
    private func loadRecentVaults() {
        if let data = UserDefaults.standard.data(forKey: recentVaultsKey),
           let decoded = try? JSONDecoder().decode([VaultReference].self, from: data) {
            recentVaults = decoded.sorted { $0.lastAccessedDate > $1.lastAccessedDate }
        }
    }
    
    private func saveRecentVaults() {
        if let encoded = try? JSONEncoder().encode(recentVaults) {
            UserDefaults.standard.set(encoded, forKey: recentVaultsKey)
        }
    }
    
    private func addToRecentVaults(_ vault: Vault) {
        let reference = VaultReference(vault: vault)
        
        // Remove existing reference if present
        recentVaults.removeAll { $0.path == reference.path }
        
        // Add to front
        recentVaults.insert(reference, at: 0)
        
        // Keep only last 10
        if recentVaults.count > 10 {
            recentVaults = Array(recentVaults.prefix(10))
        }
        
        saveRecentVaults()
    }
}
