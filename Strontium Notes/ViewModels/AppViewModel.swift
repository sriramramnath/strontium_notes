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
    @Published var isVaultPickerPresented = false
    @Published var isCreateVaultPresented = false
    @Published var searchText = ""
    @Published var selectedSidebarItem: SidebarItem = .files
    @Published var showingPreferences = false
    @Published var showingAbout = false
    @Published var showRightSidebar = true
    @Published var editorMode: EditorMode = .wysiwym
    @Published var isEditingNote = false
    @Published var showCommandPalette = false
    
    // Mock data for UI development
    @Published var mockNotes: [Note] = []
    @Published var mockFolders: [Folder] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMockData()
    }
    
    // MARK: - Vault Operations
    
    func openVault() {
        isVaultPickerPresented = true
    }
    
    func createNewVault() {
        isCreateVaultPresented = true
    }
    
    func selectNote(_ note: Note) {
        selectedNote = note
        editorMode = .wysiwym // Always open notes in WYSIWYM mode
        isEditingNote = false
    }
    
    func createNewNote() {
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        let newNote = Note(
            filePath: "Untitled Note.md",
            title: "Untitled Note",
            content: "# Untitled Note\n\nCreated on \(timestamp)\n\nStart writing your thoughts here..."
        )
        
        mockNotes.append(newNote)
        selectedNote = newNote
        editorMode = .wysiwym // Switch to editing mode
    }
    
    // MARK: - Mock Data Setup
    
    private func setupMockData() {
        // Create mock vault
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let vaultURL = documentsURL.appendingPathComponent("Strontium Notes")
        
        currentVault = Vault(
            name: "Strontium Notes",
            rootURL: vaultURL
        )
        
        // Create mock notes
        mockNotes = [
            Note(
                filePath: "Getting Started.md",
                title: "Getting Started",
                content: """
                # Getting Started with Strontium Notes
                
                Welcome to your new **knowledge management system**! Here are some tips to get you started:
                
                ## Creating Notes
                - Use the **New Note** button to create a new note
                - Notes are written in *Markdown format*
                - You can link to other notes using [[Note Name]] syntax
                - Add `inline code` for technical terms
                
                ## Organizing Your Knowledge
                - Use #tags to categorize your notes
                - Create folders to organize related notes
                - Use the search function to quickly find information
                
                ## Advanced Features
                - **Backlinks**: See which notes link to the current note
                - **WYSIWYM Editor**: Edit with live markdown rendering
                - **Templates**: Create reusable note templates
                
                ### Code Example
                ```swift
                let note = Note(title: "My Note", content: "Hello World")
                ```
                
                Happy note-taking! 📝
                """
            ),
            Note(
                filePath: "Project Ideas.md",
                title: "Project Ideas",
                content: """
                # Project Ideas
                
                A collection of interesting project ideas to explore:
                
                ## Software Projects
                - [ ] Build a personal knowledge management app
                - [ ] Create a habit tracking application
                - [ ] Develop a markdown-based blog generator
                
                ## Learning Goals
                - [ ] Master SwiftUI animations
                - [ ] Learn about Core Data optimization
                - [ ] Explore machine learning with CreateML
                
                #projects #ideas #todo
                """
            ),
            Note(
                filePath: "Daily Notes/2024-10-29.md",
                title: "2024-10-29",
                content: """
                # Daily Note - October 29, 2024
                
                ## Today's Focus
                - Working on [[Strontium Notes]] development
                - Implementing the core UI components
                - Testing the markdown editor functionality
                
                ## Ideas
                - Consider adding a dark mode toggle
                - Implement keyboard shortcuts for common actions
                - Add support for custom themes
                
                ## Links
                - Related to [[Project Ideas]]
                - See also [[Getting Started]]
                
                #daily #development
                """
            )
        ]
        
        // Create mock folders
        mockFolders = [
            Folder(name: "Daily Notes", path: "Daily Notes"),
            Folder(name: "Projects", path: "Projects"),
            Folder(name: "Resources", path: "Resources")
        ]
    }
}

/// Represents different sidebar sections
enum SidebarItem: String, CaseIterable {
    case files = "Files"
    case search = "Search"
    case tags = "Tags"
    case backlinks = "Backlinks"
    
    var systemImage: String {
        switch self {
        case .files: return "folder"
        case .search: return "magnifyingglass"
        case .tags: return "tag"
        case .backlinks: return "link"
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