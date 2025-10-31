//
//  AppViewModel.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation
import SwiftUI
import Combine

/// Main application view model that coordinates the overall app state
@MainActor
class AppViewModel: ObservableObject {
    @Published var currentVault: Vault?
    @Published var selectedNote: Note?
    @Published var recentVaults: [VaultReference] = []
    @Published var searchText = ""
    @Published var selectedSidebarItem: SidebarItem = .files
    @Published var showRightSidebar = true
    @Published var editorMode: EditorMode = .wysiwym
    @Published var isEditingNote = false
    @Published var showCommandPalette = false
    @Published var currentError: Error?
    @Published var showError = false
    
    // Centralized modal state
    @Published var presentedSheet: PresentedSheet? = nil
    @Published var sortOption: SortOption = .nameAscending
    @Published var selectedFolderId: UUID?
    @Published var selectedTags: Set<String> = []
    @Published var workspaceLayout: WorkspaceLayout = WorkspaceLayout()
    @Published var enableMultiPane = false
    
    // Services
    let vaultManager: VaultManager
    let noteManager: NoteManager
    let linkResolver: LinkResolver
    let backlinkManager: BacklinkManager
    let searchEngine: SearchEngine
    let tagManager: TagManager
    let attachmentManager: AttachmentManager
    
    // Mock data for UI development (kept for backward compatibility)
    @Published var mockNotes: [Note] = []
    @Published var mockFolders: [Folder] = []
    
    // Computed property for filtered notes
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return mockNotes
        }
        return mockNotes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Computed property for all tags
    var allTags: [String: Int] {
        return getAllTags()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize services
        self.vaultManager = VaultManager()
        self.noteManager = NoteManager()
        self.linkResolver = LinkResolver()
        self.backlinkManager = BacklinkManager(linkResolver: linkResolver)
        self.searchEngine = SearchEngine()
        self.tagManager = TagManager()
        self.attachmentManager = AttachmentManager()
        
        setupBindings()
        setupMockData()
        
        // Auto-open default vault on launch
        Task {
            await autoOpenDefaultVault()
        }
    }
    
    private func autoOpenDefaultVault() async {
        // Don't auto-open any vault - user must explicitly choose a folder
        // This ensures only local folder opening is available
        currentVault = nil
    }
    
    private func setupBindings() {
        // Observe vault changes
        vaultManager.$currentVault
            .assign(to: &$currentVault)
        
        vaultManager.$recentVaults
            .assign(to: &$recentVaults)
        
        // Update mock data when vault changes
        $currentVault
            .sink { [weak self] vault in
                guard let self = self, let vault = vault else { return }
                self.mockNotes = vault.notes
                self.mockFolders = vault.folders
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Vault Operations
    
    func openVault() {
        presentedSheet = .vaultPicker
    }
    
    func openVault(at url: URL) async {
        do {
            let vault = try await vaultManager.openVault(at: url)
            await searchEngine.buildIndex(for: vault)
            await tagManager.rebuildTagIndex(for: vault)
        } catch {
            ErrorHandler.log(error, context: "openVault")
            currentError = error
            showError = true
        }
    }
    
    func createNewVault() {
        presentedSheet = .createVault
    }
    
    func createVault(name: String, at url: URL) async {
        do {
            _ = try await vaultManager.createVault(name: name, at: url)
        } catch {
            ErrorHandler.log(error, context: "createVault")
            currentError = error
            showError = true
        }
    }
    
    func selectNote(_ note: Note) {
        selectedNote = note
        editorMode = .wysiwym // Always open notes in WYSIWYM mode
        isEditingNote = false
    }
    
    func createNewNote(in folderId: UUID? = nil) {
        // Create note immediately with mock data for now
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let newNote = Note(
            filePath: "Untitled Note \(mockNotes.count + 1).md",
            title: "Untitled Note \(mockNotes.count + 1)",
            content: "# Untitled Note\n\nCreated on \(timestamp)\n\nStart writing your thoughts here..."
        )
        
        mockNotes.append(newNote)
        selectedNote = newNote
        editorMode = .edit
        
        // Also try to create it in the vault if one is open
        if let vault = currentVault {
            Task {
                do {
                    let savedNote = try await noteManager.createNote(
                        title: newNote.title,
                        content: newNote.content,
                        in: vault,
                        folderPath: nil
                    )
                    
                    // Update the note with the saved version
                    if let index = mockNotes.firstIndex(where: { $0.id == newNote.id }) {
                        mockNotes[index] = savedNote
                        if selectedNote?.id == newNote.id {
                            selectedNote = savedNote
                        }
                    }
                    
                    // Refresh vault
                    try await vaultManager.refreshCurrentVault()
                    
                    // Update search index
                    await searchEngine.updateIndex(for: savedNote, in: vault)
                } catch {
                    ErrorHandler.log(error, context: "createNewNote")
                }
            }
        }
    }
    
    // Legacy method for compatibility
    func createNewNote() {
        createNewNote(in: nil)
    }
    
    func saveNote(_ note: Note) async {
        // Update in mock notes first
        if let index = mockNotes.firstIndex(where: { $0.id == note.id }) {
            mockNotes[index] = note
        }
        
        // Update selected note if it's the same
        if selectedNote?.id == note.id {
            selectedNote = note
        }
        
        // Save to vault if one is open
        guard let vault = currentVault else { return }
        
        do {
            try await noteManager.saveNote(note)
            await searchEngine.updateIndex(for: note, in: vault)
            await tagManager.updateTagIndex(for: note, in: vault)
            await backlinkManager.updateBacklinks(for: note, in: vault)
        } catch {
            ErrorHandler.log(error, context: "saveNote")
            currentError = error
            showError = true
        }
    }
    
    func deleteNote(_ note: Note) async {
        guard let vault = currentVault else { return }
        
        do {
            try await noteManager.deleteNote(note)
            await searchEngine.removeFromIndex(noteID: note.id, in: vault)
            await tagManager.removeTagsForNote(note.id, in: vault)
            try await vaultManager.refreshCurrentVault()
            
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
        } catch {
            ErrorHandler.log(error, context: "deleteNote")
            currentError = error
            showError = true
        }
    }
    
    func renameNote(_ note: Note, to newTitle: String) async {
        guard let vault = currentVault else { return }
        
        do {
            let renamedNote = try await noteManager.renameNote(note, to: newTitle)
            
            // Update all links to this note
            _ = try await linkResolver.updateLinksForRenamedNote(
                oldTitle: note.title,
                newTitle: newTitle,
                in: vault
            )
            
            try await vaultManager.refreshCurrentVault()
            selectedNote = renamedNote
        } catch {
            ErrorHandler.log(error, context: "renameNote")
            currentError = error
            showError = true
        }
    }
    
    func searchNotes(query: String) async -> [SearchResult] {
        guard let vault = currentVault else { return [] }
        return await searchEngine.quickSearch(query, in: vault)
    }
    
    // MARK: - Mock Data Setup
    
    private func setupMockData() {
        // Don't create mock data - wait for user to open a folder
        mockNotes = []
        mockFolders = []
    }
    
    func getBacklinks(for note: Note) -> [Backlink] {
        guard let vault = currentVault else { return [] }
        return backlinkManager.getBacklinks(for: note.id, in: vault)
    }
    
    func getNotesWithTag(_ tag: String) -> [Note] {
        guard let vault = currentVault else { return [] }
        return tagManager.getNotesWithTag(tag, in: vault)
    }
    
    func getAllTags() -> [String: Int] {
        guard let vault = currentVault else { return [:] }
        return tagManager.getAllTags(in: vault)
    }
    
    // MARK: - Folder Operations (Placeholder implementations)
    
    func createNewFolder(name: String) {
        // TODO: Implement folder creation
        let folder = Folder(name: name, path: name)
        mockFolders.append(folder)
    }
    
    func getSubfolders(of parentId: UUID?) -> [Folder] {
        return mockFolders.filter { $0.parentID == parentId }
    }
    
    func toggleFolderExpansion(_ folder: Folder) {
        if let index = mockFolders.firstIndex(where: { $0.id == folder.id }) {
            mockFolders[index].toggleExpansion()
        }
    }
    
    func renameFolder(_ folder: Folder, to newName: String) {
        if let index = mockFolders.firstIndex(where: { $0.id == folder.id }) {
            mockFolders[index].rename(to: newName)
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        mockFolders.removeAll { $0.id == folder.id }
    }
    
    func getNotesCount(in folderId: UUID) -> Int {
        // TODO: Implement proper folder-based note counting
        return mockNotes.count
    }
    
    func moveNote(_ note: Note, to folderId: UUID) {
        // TODO: Implement note moving between folders
    }
    
    // MARK: - Workspace Operations
    
    func splitPaneHorizontally() {
        guard let selectedNote = selectedNote else { return }
        let newPane = Pane(noteID: selectedNote.id, width: 0.5)
        workspaceLayout.panes.append(newPane)
        workspaceLayout.splitDirection = .horizontal
        enableMultiPane = true
    }
    
    func splitPaneVertically() {
        guard let selectedNote = selectedNote else { return }
        let newPane = Pane(noteID: selectedNote.id, width: 0.5)
        workspaceLayout.panes.append(newPane)
        workspaceLayout.splitDirection = .vertical
        enableMultiPane = true
    }
    
    func closePane(_ paneId: UUID) {
        workspaceLayout.panes.removeAll { $0.id == paneId }
        if workspaceLayout.panes.isEmpty {
            enableMultiPane = false
        }
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case dateModified = "Date Modified"
    case dateCreated = "Date Created"
    
    var systemImage: String {
        switch self {
        case .nameAscending: return "arrow.up.arrow.down"
        case .nameDescending: return "arrow.down.arrow.up"
        case .dateModified: return "clock"
        case .dateCreated: return "calendar"
        }
    }
}

/// Represents different sidebar sections
enum SidebarItem: String, CaseIterable {
    case files = "Files"
    case search = "Search"
    case tags = "Tags"
    case backlinks = "Backlinks"
    case daily = "Daily"
    case stats = "Stats"
    
    var systemImage: String {
        switch self {
        case .files: return "folder"
        case .search: return "magnifyingglass"
        case .tags: return "tag"
        case .backlinks: return "link"
        case .daily: return "calendar"
        case .stats: return "chart.bar"
        }
    }
}

/// Editor display modes
enum EditorMode: String, CaseIterable {
    case wysiwym = "WYSIWYM"
    case edit = "Edit"
    case preview = "Preview"
    case livePreview = "Live Preview"
    
    var systemImage: String {
        switch self {
        case .wysiwym: return "doc.richtext"
        case .edit: return "pencil"
        case .preview: return "eye"
        case .livePreview: return "eye.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .wysiwym: return "WYSIWYM"
        case .edit: return "Edit"
        case .preview: return "Preview"
        case .livePreview: return "Live"
        }
    }
}

/// Centralized modal presentation state
enum PresentedSheet: Identifiable {
    case vaultPicker
    case createVault
    case preferences
    case about
    case renameNote
    case createFolder
    
    var id: String {
        switch self {
        case .vaultPicker: return "vaultPicker"
        case .createVault: return "createVault"
        case .preferences: return "preferences"
        case .about: return "about"
        case .renameNote: return "renameNote"
        case .createFolder: return "createFolder"
        }
    }
}