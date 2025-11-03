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
    @Published var showAIPanel = false
    @Published var currentError: Error?
    @Published var showError = false
    
    // AI Settings
    @Published var aiProvider: AIProvider = .gemini
    @Published var geminiAPIKey: String = "" {
        didSet {
            // Save to UserDefaults whenever it changes
            UserDefaults.standard.set(geminiAPIKey, forKey: "geminiAPIKey")
        }
    }
    
    // Tab management
    @Published var openTabs: [NoteTab] = []
    @Published var activeTabId: UUID?
    
    // Centralized modal state
    @Published var presentedSheet: PresentedSheet? = nil
    @Published var sortOption: SortOption = .nameAscending
    @Published var selectedFolderId: UUID?
    @Published var selectedTags: Set<String> = []
    @Published var workspaceLayout: WorkspaceLayout = WorkspaceLayout()
    @Published var enableMultiPane = false
    
    // View state
    @Published var showFileExtensions = false
    @Published var expandedFolders: Set<String> = ["root"]
    @Published var viewMode: ViewMode = .edit
    @Published var splitViewMode: SplitViewMode = .none
    
    // Services
    let vaultManager: VaultManager
    let noteManager: NoteManager
    let linkResolver: LinkResolver
    let backlinkManager: BacklinkManager
    let searchEngine: SearchEngine
    let tagManager: TagManager
    let attachmentManager: AttachmentManager
    let aiService = AIService()
    
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
        
        // Load saved API key
        if let savedAPIKey = UserDefaults.standard.string(forKey: "geminiAPIKey") {
            self.geminiAPIKey = savedAPIKey
        }
        
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
            // Only show error if it's not a permission error on startup
            let nsError = error as NSError
            if nsError.domain != NSCocoaErrorDomain || nsError.code != NSFileReadNoPermissionError {
                ErrorHandler.log(error, context: "openVault")
                await MainActor.run {
                    currentError = error
                    showError = true
                }
            }
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
        openNoteInTab(note)
        editorMode = .wysiwym // Always open notes in WYSIWYM mode
        isEditingNote = false
    }
    
    func createNewNote(in folderId: UUID? = nil) {
        guard let vault = currentVault else { return }
        
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let noteTitle = "Untitled Note \(mockNotes.count + 1)"
        let noteContent = "# \(noteTitle)\n\nCreated on \(timestamp)\n\nStart writing your thoughts here..."
        
        Task {
            do {
                // Create the note directly in the vault
                let savedNote = try await noteManager.createNote(
                    title: noteTitle,
                    content: noteContent,
                    in: vault,
                    folderPath: nil
                )
                
                // Add to mock notes and select it
                await MainActor.run {
                    mockNotes.append(savedNote)
                    selectedNote = savedNote
                    editorMode = .edit
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
            // Get absolute path
            let fileURL = vault.rootURL.appendingPathComponent(note.filePath)
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw NoteError.fileNotFound
            }
            
            // Delete the actual file
            try FileManager.default.removeItem(at: fileURL)
            
            await searchEngine.removeFromIndex(noteID: note.id, in: vault)
            await tagManager.removeTagsForNote(note.id, in: vault)
            
            // Remove from mockNotes array
            await MainActor.run {
                mockNotes.removeAll { $0.id == note.id }
            }
            
            // Close any tabs with this note
            openTabs.removeAll { $0.noteId == note.id }
            
            // Clear selection if this note was selected
            if selectedNote?.id == note.id {
                selectedNote = nil
                activeTabId = nil
            }
            
            try await vaultManager.refreshCurrentVault()
        } catch {
            ErrorHandler.log(error, context: "deleteNote")
            currentError = error
            showError = true
        }
    }
    
    func renameNote(_ note: Note, to newTitle: String) async {
        guard let vault = currentVault else { return }
        
        do {
            // Get absolute paths
            let oldURL = vault.rootURL.appendingPathComponent(note.filePath)
            let directory = oldURL.deletingLastPathComponent()
            let newFileName = sanitizeFileName(newTitle) + ".md"
            let newURL = directory.appendingPathComponent(newFileName)
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: oldURL.path) else {
                throw NoteError.fileNotFound
            }
            
            // Check if target already exists
            if FileManager.default.fileExists(atPath: newURL.path) {
                throw NoteError.duplicateTitle
            }
            
            // Move the actual file
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            
            // Calculate new relative path
            let newRelativePath = newURL.path.replacingOccurrences(of: vault.rootURL.path + "/", with: "")
            
            // Create renamed note
            let renamedNote = Note(filePath: newRelativePath, title: newTitle, content: note.content)
            
            // Update all links to this note
            _ = try await linkResolver.updateLinksForRenamedNote(
                oldTitle: note.title,
                newTitle: newTitle,
                in: vault
            )
            
            // Update mockNotes array
            await MainActor.run {
                if let index = mockNotes.firstIndex(where: { $0.id == note.id }) {
                    mockNotes[index] = renamedNote
                }
            }
            
            // Update open tabs
            if let tabIndex = openTabs.firstIndex(where: { $0.noteId == note.id }) {
                openTabs[tabIndex].title = newTitle
            }
            
            // Update selected note
            selectedNote = renamedNote
            
            try await vaultManager.refreshCurrentVault()
        } catch {
            ErrorHandler.log(error, context: "renameNote")
            currentError = error
            showError = true
        }
    }
    
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "-")
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
    
    // MARK: - Folder Operations
    
    func createNewFolder(name: String) {
        guard let vault = currentVault else { return }
        
        // Create folder in the file system
        let folderURL = vault.rootURL.appendingPathComponent(name)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // Add to mock folders
            let folder = Folder(name: name, path: name)
            mockFolders.append(folder)
            
            // Refresh vault
            Task {
                try? await vaultManager.refreshCurrentVault()
            }
        } catch {
            ErrorHandler.log(error, context: "createNewFolder")
            currentError = error
            showError = true
        }
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
    
    // MARK: - Sorting Operations
    
    func sortNotes(by option: SortOption) {
        sortOption = option
        switch option {
        case .nameAscending:
            mockNotes.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nameDescending:
            mockNotes.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .dateModified:
            mockNotes.sort { $0.modifiedDate > $1.modifiedDate }
        case .dateCreated:
            mockNotes.sort { $0.createdDate > $1.createdDate }
        }
    }
    
    // MARK: - Folder Operations
    
    func collapseAllFolders() {
        expandedFolders.removeAll()
    }
    
    func expandAllFolders() {
        expandedFolders = Set(mockFolders.map { $0.id.uuidString })
        expandedFolders.insert("root")
    }
    
    func toggleFolderExpansion(_ folderId: String) {
        if expandedFolders.contains(folderId) {
            expandedFolders.remove(folderId)
        } else {
            expandedFolders.insert(folderId)
        }
    }
    
    // MARK: - View Mode Operations
    
    func toggleViewMode() {
        switch viewMode {
        case .edit:
            viewMode = .reading
        case .reading:
            viewMode = .source
        case .source:
            viewMode = .edit
        }
    }
    
    func setSplitView(_ mode: SplitViewMode) {
        splitViewMode = mode
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
    case upgrade
    
    var id: String {
        switch self {
        case .vaultPicker: return "vaultPicker"
        case .createVault: return "createVault"
        case .preferences: return "preferences"
        case .about: return "about"
        case .renameNote: return "renameNote"
        case .createFolder: return "createFolder"
        case .upgrade: return "upgrade"
        }
    }
}

/// View modes for the editor
enum ViewMode: String {
    case edit = "Edit"
    case reading = "Reading"
    case source = "Source"
}

/// Split view modes
enum SplitViewMode: String {
    case none = "None"
    case horizontal = "Horizontal"
    case vertical = "Vertical"
}

/// AI Provider options
enum AIProvider: String, CaseIterable {
    case gemini = "Google Gemini"
    
    var icon: String {
        return "sparkles"
    }
}

// MARK: - Tab Management
extension AppViewModel {
    func openNoteInTab(_ note: Note) {
        // Check if note is already open in a tab
        if let existingTab = openTabs.first(where: { $0.noteId == note.id }) {
            activeTabId = existingTab.id
            selectedNote = note
            return
        }
        
        // Create new tab
        let newTab = NoteTab(noteId: note.id, title: note.title)
        openTabs.append(newTab)
        activeTabId = newTab.id
        selectedNote = note
    }
    
    func closeTab(_ tabId: UUID) {
        guard let index = openTabs.firstIndex(where: { $0.id == tabId }) else { return }
        openTabs.remove(at: index)
        
        // If closing active tab, switch to another tab
        if activeTabId == tabId {
            if !openTabs.isEmpty {
                let newIndex = min(index, openTabs.count - 1)
                activeTabId = openTabs[newIndex].id
                if let note = mockNotes.first(where: { $0.id == openTabs[newIndex].noteId }) {
                    selectedNote = note
                }
            } else {
                activeTabId = nil
                selectedNote = nil
            }
        }
    }
    
    func switchToTab(_ tabId: UUID) {
        guard let tab = openTabs.first(where: { $0.id == tabId }) else { return }
        activeTabId = tabId
        if let note = mockNotes.first(where: { $0.id == tab.noteId }) {
            selectedNote = note
        }
    }
}

// MARK: - NoteTab Model

struct NoteTab: Identifiable {
    let id = UUID()
    let noteId: UUID
    var title: String
}
