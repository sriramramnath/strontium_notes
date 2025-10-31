//
//  VSCodeStyleView.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

struct VSCodeStyleView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var sidebarWidth: CGFloat = 250
    @State private var showCommandPalette = false
    
    var body: some View {
        Group {
            if appViewModel.currentVault == nil {
                // Welcome screen - only show folder picker
                VStack(spacing: 24) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(Color.accent)
                    
                    Text("Welcome to Strontium Notes")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.primaryText)
                    
                    Text("Open a folder to get started")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText)
                    
                    Button(action: {
                        openFolderPicker()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                            Text("Open Folder")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accent)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primaryBackground)
            } else {
                // Main interface
                HStack(spacing: 0) {
                    // Activity Bar (left icons)
                    ActivityBar(appViewModel: appViewModel)
                        .frame(width: 48)
                    
                    // Sidebar
                    VSCodeSidebar(appViewModel: appViewModel)
                        .frame(width: sidebarWidth)
                    
                    // Editor Area
                    VSCodeEditor(appViewModel: appViewModel)
                }
                .background(Color.primaryBackground)
            }
        }
        .sheet(item: $appViewModel.presentedSheet) { sheet in
            switch sheet {
            case .preferences:
                SettingsView(appViewModel: appViewModel)
            case .renameNote:
                if let note = appViewModel.selectedNote {
                    RenameNoteView(appViewModel: appViewModel, note: note)
                }
            case .createFolder:
                CreateFolderView(appViewModel: appViewModel)
            default:
                EmptyView()
            }
        }
        .overlay(
            Group {
                if appViewModel.showCommandPalette {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            appViewModel.showCommandPalette = false
                        }
                    
                    QuickCommandPalette(appViewModel: appViewModel, isPresented: $appViewModel.showCommandPalette)
                        .frame(maxWidth: 600)
                        .padding(.top, 100)
                }
            }
        )
        .onAppear {
            // Set up keyboard shortcuts
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) {
                    switch event.charactersIgnoringModifiers {
                    case "n": // Cmd+N - New note
                        appViewModel.createNewNote()
                        return nil
                    case "s": // Cmd+S - Save (handled in editor)
                        return event
                    case "w": // Cmd+W - Close tab
                        appViewModel.selectedNote = nil
                        return nil
                    case "f": // Cmd+F - Focus search
                        appViewModel.selectedSidebarItem = .search
                        return nil
                    case "o": // Cmd+O - Open folder
                        if event.modifierFlags.contains(.shift) {
                            openFolderPicker()
                            return nil
                        }
                    case ",": // Cmd+, - Settings
                        appViewModel.presentedSheet = .preferences
                        return nil
                    case "p": // Cmd+P - Command Palette
                        if event.modifierFlags.contains(.shift) {
                            appViewModel.showCommandPalette.toggle()
                            return nil
                        }
                    case "k": // Cmd+K - Command Palette
                        appViewModel.showCommandPalette.toggle()
                        return nil
                    default:
                        break
                    }
                }
                return event
            }
        }
    }
    
    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to open as your vault"
        panel.prompt = "Open Folder"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    await appViewModel.openVault(at: url)
                }
            }
        }
    }
}

// Activity Bar (left icon bar like VS Code)
struct ActivityBar: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top icons
            VStack(spacing: 8) {
                ActivityBarIcon(icon: "doc.text.fill", isSelected: appViewModel.selectedSidebarItem == .files) {
                    appViewModel.selectedSidebarItem = .files
                }
                
                ActivityBarIcon(icon: "magnifyingglass", isSelected: appViewModel.selectedSidebarItem == .search) {
                    appViewModel.selectedSidebarItem = .search
                }
                
                ActivityBarIcon(icon: "number", isSelected: appViewModel.selectedSidebarItem == .tags) {
                    appViewModel.selectedSidebarItem = .tags
                }
                
                ActivityBarIcon(icon: "link", isSelected: appViewModel.selectedSidebarItem == .backlinks) {
                    appViewModel.selectedSidebarItem = .backlinks
                }
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Bottom icons
            VStack(spacing: 8) {
ActivityBarIcon(icon: "folder", isSelected: false) {
                    // Open folder action
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.message = "Select a folder to open as your vault"
                    panel.prompt = "Open Folder"
                    
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            Task {
                                await appViewModel.openVault(at: url)
                            }
                        }
                    }
                }
                
                ActivityBarIcon(icon: "gearshape.fill", isSelected: false) {
                    appViewModel.presentedSheet = .preferences
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.082, green: 0.082, blue: 0.082)) // #151515 - VS Code activity bar
    }
}

struct ActivityBarIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .white : (isHovered ? Color.primaryText : Color.tertiaryText))
                .frame(width: 48, height: 48)
                .background(isSelected ? Color.clear : Color.clear)
                .overlay(
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2)
                        .opacity(isSelected ? 1 : 0),
                    alignment: .leading
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// VS Code-style Sidebar
struct VSCodeSidebar: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(sidebarTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.primaryText)
                    .textCase(.uppercase)
                
                Spacer()
                
                if appViewModel.selectedSidebarItem == .files {
                    Menu {
                        Button(action: { appViewModel.createNewNote() }) {
                            Label("New Note", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: { 
                            appViewModel.presentedSheet = .createFolder
                        }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.primaryText)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.secondaryBackground)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch appViewModel.selectedSidebarItem {
                    case .files:
                        VSCodeFileTree(appViewModel: appViewModel)
                    case .search:
                        VSCodeSearchView(appViewModel: appViewModel)
                    case .tags:
                        VSCodeTagsView(appViewModel: appViewModel)
                    case .backlinks:
                        VSCodeBacklinksView(appViewModel: appViewModel)
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .background(Color.secondaryBackground)
    }
    
    private var sidebarTitle: String {
        switch appViewModel.selectedSidebarItem {
        case .files: return "Explorer"
        case .search: return "Search"
        case .tags: return "Tags"
        case .backlinks: return "Backlinks"
        case .daily: return "Daily Notes"
        case .stats: return "Statistics"
        }
    }
}

// VS Code-style File Tree with folder support
struct VSCodeFileTree: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var expandedFolders: Set<String> = ["root"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Vault name as root
            VSCodeTreeItem(
                icon: "folder.fill",
                title: appViewModel.currentVault?.name ?? "Strontium Notes",
                isExpanded: expandedFolders.contains("root"),
                level: 0,
                onToggle: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedFolders.contains("root") {
                            expandedFolders.remove("root")
                        } else {
                            expandedFolders.insert("root")
                        }
                    }
                }
            )
            
            if expandedFolders.contains("root") {
                // Show folders first
                ForEach(appViewModel.mockFolders) { folder in
                    VSCodeFolderItem(
                        folder: folder,
                        isExpanded: expandedFolders.contains(folder.id.uuidString),
                        level: 1,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedFolders.contains(folder.id.uuidString) {
                                    expandedFolders.remove(folder.id.uuidString)
                                } else {
                                    expandedFolders.insert(folder.id.uuidString)
                                }
                            }
                        }
                    )
                    
                    // Show notes in this folder if expanded
                    if expandedFolders.contains(folder.id.uuidString) {
                        ForEach(appViewModel.mockNotes.filter { $0.filePath.hasPrefix(folder.path) }) { note in
                            VSCodeFileItem(
                                appViewModel: appViewModel,
                                note: note,
                                isSelected: appViewModel.selectedNote?.id == note.id,
                                level: 2,
                                onSelect: {
                                    appViewModel.selectNote(note)
                                }
                            )
                        }
                    }
                }
                
                // Show root level notes
                ForEach(appViewModel.mockNotes.filter { !$0.filePath.contains("/") }) { note in
                    VSCodeFileItem(
                        appViewModel: appViewModel,
                        note: note,
                        isSelected: appViewModel.selectedNote?.id == note.id,
                        level: 1,
                        onSelect: {
                            appViewModel.selectNote(note)
                        }
                    )
                }
                
                // Empty state
                if appViewModel.mockNotes.isEmpty {
                    HStack {
                        Text("No notes yet")
                            .font(.system(size: 12))
                            .foregroundColor(Color.tertiaryText)
                            .italic()
                    }
                    .padding(.leading, 32)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// Folder item in tree
struct VSCodeFolderItem: View {
    let folder: Folder
    let isExpanded: Bool
    let level: Int
    let onToggle: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.tertiaryText)
                    .frame(width: 12)
                
                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .font(.system(size: 14))
                    .foregroundColor(Color.accent)
                
                Text(folder.name)
                    .font(.system(size: 13))
                    .foregroundColor(Color.primaryText)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level * 12 + 8))
            .padding(.vertical, 4)
            .background(isHovered ? Color.primaryBackground : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct VSCodeTreeItem: View {
    let icon: String
    let title: String
    let isExpanded: Bool
    let level: Int
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.tertiaryText)
                    .frame(width: 12)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.accent)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Color.primaryText)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level * 12 + 8))
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct VSCodeFileItem: View {
    @ObservedObject var appViewModel: AppViewModel
    let note: Note
    let isSelected: Bool
    let level: Int
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color.secondaryText)
                
                Text(note.title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color.primaryText)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level * 16 + 8))
            .padding(.vertical, 3)
            .background(isSelected ? Color.accent : (isHovered ? Color.tertiaryBackground : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Rename") {
                appViewModel.presentedSheet = .renameNote
            }
            
            Button("Delete", role: .destructive) {
                Task {
                    await appViewModel.deleteNote(note)
                }
            }
        }
    }
}

// Search view with full functionality
struct VSCodeSearchView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var searchQuery: String = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(Color.tertiaryText)
                
                TextField("Search notes...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Color.primaryText)
                    .focused($isSearchFocused)
                    .onChange(of: searchQuery) { _, newValue in
                        performSearch(newValue)
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primaryBackground)
            .cornerRadius(4)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            Divider()
                .background(Color.primaryBorder)
                .padding(.vertical, 8)
            
            // Search results
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Searching...")
                        .font(.system(size: 12))
                        .foregroundColor(Color.tertiaryText)
                }
                .padding(.horizontal, 16)
            } else if searchQuery.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(Color.tertiaryText)
                    Text("Search your notes")
                        .font(.system(size: 13))
                        .foregroundColor(Color.secondaryText)
                    Text("Type to start searching")
                        .font(.system(size: 11))
                        .foregroundColor(Color.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(Color.tertiaryText)
                    Text("No results found")
                        .font(.system(size: 13))
                        .foregroundColor(Color.secondaryText)
                    Text("Try a different search term")
                        .font(.system(size: 11))
                        .foregroundColor(Color.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Results count
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundColor(Color.tertiaryText)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        
                        // Results list
                        ForEach(searchResults) { result in
                            SearchResultItem(result: result) {
                                // Find and open the note
                                if let note = appViewModel.mockNotes.first(where: { $0.id == result.noteID }) {
                                    appViewModel.selectNote(note)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            // Simulate search delay for better UX
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            let results = await appViewModel.searchNotes(query: query)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }
}

struct SearchResultItem: View {
    let result: SearchResult
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                // Note title
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(Color.accent)
                    
                    Text(result.noteTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.primaryText)
                        .lineLimit(1)
                }
                
                // Match preview
                if !result.matchedContent.isEmpty {
                    Text(result.matchedContent)
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondaryText)
                        .lineLimit(2)
                        .padding(.leading, 18)
                }
                
                // Match info
                HStack(spacing: 8) {
                    if result.matchCount > 1 {
                        Text("\(result.matchCount) matches")
                            .font(.system(size: 10))
                            .foregroundColor(Color.tertiaryText)
                    }
                    
                    Text("Score: \(String(format: "%.1f", result.score))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.tertiaryText)
                }
                .padding(.leading, 18)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isHovered ? Color.primaryBackground : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct VSCodeTagsView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(appViewModel.getAllTags().keys.sorted()), id: \.self) { tag in
                HStack {
                    Image(systemName: "number")
                        .font(.system(size: 12))
                        .foregroundColor(Color.accent)
                    
                    Text(tag)
                        .font(.system(size: 13))
                        .foregroundColor(Color.primaryText)
                    
                    Spacer()
                    
                    Text("\(appViewModel.getAllTags()[tag] ?? 0)")
                        .font(.system(size: 11))
                        .foregroundColor(Color.tertiaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

struct VSCodeBacklinksView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            if let note = appViewModel.selectedNote {
                let backlinks = appViewModel.getBacklinks(for: note)
                if backlinks.isEmpty {
                    Text("No backlinks")
                        .foregroundColor(Color.secondaryText)
                        .padding()
                } else {
                    ForEach(backlinks) { backlink in
                        Text(backlink.sourceNoteTitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                    }
                }
            } else {
                Text("Select a note to see backlinks")
                    .foregroundColor(Color.secondaryText)
                    .padding()
            }
        }
    }
}

// VS Code-style Editor with full editing support
struct VSCodeEditor: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var editedContent: String = ""
    @State private var isEditing = false
    @State private var showPreview = false
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let note = appViewModel.selectedNote {
                // Tab bar - Obsidian style (minimal)
                HStack(spacing: 0) {
                    // File icon and title
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText)
                        
                        Text(note.title)
                            .font(.system(size: 13))
                            .foregroundColor(Color.primaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    Spacer()
                    
                    // Right side actions
                    HStack(spacing: 4) {
                        Menu {
                            Button(action: {
                                // Rename file
                                appViewModel.presentedSheet = .renameNote
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                // Delete file
                                if let note = appViewModel.selectedNote {
                                    Task {
                                        await appViewModel.deleteNote(note)
                                    }
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                // Copy path
                                if let note = appViewModel.selectedNote {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(note.filePath, forType: .string)
                                }
                            }) {
                                Label("Copy Path", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: {
                                // Reveal in Finder
                                if let vault = appViewModel.currentVault, let note = appViewModel.selectedNote {
                                    let fileURL = vault.rootURL.appendingPathComponent(note.filePath)
                                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                                }
                            }) {
                                Label("Reveal in Finder", systemImage: "folder")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondaryText)
                                .frame(width: 30, height: 30)
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        
                        Button(action: {
                            appViewModel.selectedNote = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(Color.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                }
                .background(Color.primaryBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.primaryBorder)
                        .frame(height: 1),
                    alignment: .bottom
                )
                

                
                // Live Preview Editor - edit and see formatted result
                VSCodeLiveEditor(
                    content: $editedContent,
                    isEditing: $isEditing,
                    isEditorFocused: $isEditorFocused
                )
                
                // Status bar - Obsidian style
                HStack(spacing: 16) {
                    // Left side
                    HStack(spacing: 12) {
                        Text("0 backlinks")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondaryText)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(Color.secondaryText)
                        
                        Text("\(wordCount) words")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondaryText)
                        
                        Text("\(editedContent.count) characters")
                            .font(.system(size: 11))
                            .foregroundColor(Color.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.secondaryBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.primaryBorder)
                        .frame(height: 1),
                    alignment: .top
                )
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(Color.tertiaryText)
                    
                    Text("No file selected")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText)
                    
                    Button("Create New Note") {
                        appViewModel.createNewNote()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.primaryBackground)
        .onAppear {
            if let note = appViewModel.selectedNote {
                editedContent = note.content
                isEditing = false
            }
        }
        .onChange(of: appViewModel.selectedNote?.id) { _, _ in
            if let note = appViewModel.selectedNote {
                editedContent = note.content
                isEditing = false
                isEditorFocused = true
            }
        }
        .onChange(of: editedContent) { _, _ in
            // Auto-save after 2 seconds of no typing
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if isEditing {
                    await saveNote()
                }
            }
        }
    }
    
    private var wordCount: Int {
        editedContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private func saveNote() async {
        guard let note = appViewModel.selectedNote else { return }
        
        let updatedNote = Note(
            filePath: note.filePath,
            title: note.title,
            content: editedContent
        )
        
        await appViewModel.saveNote(updatedNote)
        isEditing = false
    }
}

// VS Code-style Tab


// Live Editor - Full width like Obsidian
struct VSCodeLiveEditor: View {
    @Binding var content: String
    @Binding var isEditing: Bool
    @FocusState.Binding var isEditorFocused: Bool
    
    var body: some View {
        MarkdownTextEditor(text: $content, isEditing: $isEditing)
            .focused($isEditorFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
    }
}

// Markdown-aware text editor with proper formatting
struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isRichText = true  // Enable rich text for styling
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = NSColor(Color.primaryText)
        textView.backgroundColor = NSColor(Color.primaryBackground)
        textView.insertionPointColor = NSColor(Color.accent)
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.usesAdaptiveColorMappingForDarkAppearance = false
        
        // Enable line wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 10
        
        // Smooth scrolling
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.backgroundColor = NSColor(Color.primaryBackground)
        scrollView.drawsBackground = true
        
        // Rounded corners
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 8
        scrollView.layer?.masksToBounds = true
        
        // Set initial text
        textView.string = text
        
        // Apply styling after a brief delay to ensure text view is ready
        DispatchQueue.main.async { [weak textView] in
            guard let textView = textView else { return }
            self.applyMarkdownStyling(to: textView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Only update if text is different and we're not currently editing
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true
            let selectedRange = textView.selectedRange()
            
            // Temporarily disable delegate to prevent recursion
            textView.delegate = nil
            textView.string = text
            applyMarkdownStyling(to: textView)
            textView.delegate = context.coordinator
            
            // Restore selection if possible
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
            context.coordinator.isUpdating = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func applyMarkdownStyling(to textView: NSTextView) {
        guard let storage = textView.textStorage, storage.length > 0 else { return }
        
        let fullRange = NSRange(location: 0, length: storage.length)
        
        // Get current line range safely
        let cursorLocation = textView.selectedRange().location
        let text = storage.string
        guard !text.isEmpty else { return }
        
        let safeCursorLocation = min(max(0, cursorLocation), text.count - 1)
        let currentLineRange = (text as NSString).lineRange(for: NSRange(location: safeCursorLocation, length: 0))
        
        // Reset to default
        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 15, weight: .regular), range: fullRange)
        storage.addAttribute(.foregroundColor, value: NSColor(Color.primaryText), range: fullRange)
        storage.removeAttribute(.backgroundColor, range: fullRange)
        storage.removeAttribute(.underlineStyle, range: fullRange)
        storage.removeAttribute(.strikethroughStyle, range: fullRange)
        
        let lines = text.components(separatedBy: .newlines)
        var currentLocation = 0
        var inCodeBlock = false
        var tableRowCount = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: currentLocation, length: lineLength)
            let isCurrentLine = NSIntersectionRange(lineRange, currentLineRange).length > 0
            
            // Code blocks ```
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCodeBlock.toggle()
                storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.6)), range: lineRange)
                storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium), range: lineRange)
                storage.addAttribute(.backgroundColor, value: NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.3), range: lineRange)
                currentLocation += lineLength + 1
                continue
            }
            
            if inCodeBlock {
                storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: lineRange)
                storage.addAttribute(.backgroundColor, value: NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 0.5), range: lineRange)
                storage.addAttribute(.foregroundColor, value: NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0), range: lineRange)
                
                // Add some padding effect
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 2
                storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineRange)
                
                currentLocation += lineLength + 1
                continue
            }
            
            // Horizontal rules - must check BEFORE tables
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if (trimmedLine == "---" || trimmedLine == "***" || trimmedLine == "___") ||
               (trimmedLine.hasPrefix("---") && trimmedLine.count >= 3 && trimmedLine.allSatisfy { $0 == "-" || $0 == " " }) ||
               (trimmedLine.hasPrefix("***") && trimmedLine.count >= 3 && trimmedLine.allSatisfy { $0 == "*" || $0 == " " }) {
                // Hide the text and draw a line
                storage.addAttribute(.foregroundColor, value: NSColor.clear, range: lineRange)
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: lineRange)
                
                // Add a border to create the line effect
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.paragraphSpacing = 12
                paragraphStyle.paragraphSpacingBefore = 12
                storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineRange)
                storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: lineRange)
                storage.addAttribute(.underlineColor, value: NSColor(Color.primaryBorder), range: lineRange)
                
                currentLocation += lineLength + 1
                continue
            }
            
            // Tables - detect lines with pipes (Notion-style)
            if trimmedLine.contains("|") && trimmedLine.components(separatedBy: "|").count >= 2 {
                // Check if it's a separator line (|---|---|)
                let isSeparator = trimmedLine.contains("---") || trimmedLine.contains(":--") || trimmedLine.contains("--:")
                
                if isSeparator {
                    // Style separator line
                    if !isCurrentLine {
                        storage.addAttribute(.foregroundColor, value: NSColor.clear, range: lineRange)
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: lineRange)
                    } else {
                        storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.3)), range: lineRange)
                        storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), range: lineRange)
                    }
                } else {
                    // Regular table row - Notion style
                    let isHeader = tableRowCount == 0
                    
                    // Set font
                    if isHeader {
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14, weight: .semibold), range: lineRange)
                    } else {
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14, weight: .regular), range: lineRange)
                    }
                    
                    // Background color - subtle like Notion
                    let bgColor: NSColor
                    if isHeader {
                        bgColor = NSColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 0.4)
                    } else {
                        bgColor = tableRowCount % 2 == 1 ? 
                            NSColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.3) : 
                            NSColor.clear
                    }
                    storage.addAttribute(.backgroundColor, value: bgColor, range: lineRange)
                    
                    // Add padding
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 6
                    storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineRange)
                    
                    // Style pipe characters - hide or dim them
                    for (index, char) in line.enumerated() {
                        if char == "|" {
                            let pipeRange = NSRange(location: currentLocation + index, length: 1)
                            if !isCurrentLine {
                                // Hide pipes when not editing
                                storage.addAttribute(.foregroundColor, value: NSColor(Color.primaryBorder.opacity(0.3)), range: pipeRange)
                            } else {
                                // Show pipes in gray when editing
                                storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: pipeRange)
                            }
                        }
                    }
                    
                    tableRowCount += 1
                }
                
                currentLocation += lineLength + 1
                continue
            } else {
                tableRowCount = 0
            }
            
            // Headers
            if line.hasPrefix("# ") {
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 36, weight: .bold), range: lineRange)
                styleMarker(storage, at: currentLocation, length: 2, isCurrentLine: isCurrentLine)
            } else if line.hasPrefix("## ") {
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 28, weight: .bold), range: lineRange)
                styleMarker(storage, at: currentLocation, length: 3, isCurrentLine: isCurrentLine)
            } else if line.hasPrefix("### ") {
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 22, weight: .semibold), range: lineRange)
                styleMarker(storage, at: currentLocation, length: 4, isCurrentLine: isCurrentLine)
            } else if line.hasPrefix("#### ") {
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 18, weight: .semibold), range: lineRange)
                styleMarker(storage, at: currentLocation, length: 5, isCurrentLine: isCurrentLine)
            } else if line.hasPrefix("##### ") {
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 16, weight: .medium), range: lineRange)
                styleMarker(storage, at: currentLocation, length: 6, isCurrentLine: isCurrentLine)
            }
            
            // Blockquotes
            if line.hasPrefix("> ") {
                storage.addAttribute(.foregroundColor, value: NSColor(Color.secondaryText), range: lineRange)
                let quoteMarker = NSRange(location: currentLocation, length: 2)
                storage.addAttribute(.foregroundColor, value: NSColor(Color.accent.opacity(0.6)), range: quoteMarker)
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 18, weight: .bold), range: quoteMarker)
            }
            
            // Lists
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                let bulletRange = NSRange(location: currentLocation, length: 2)
                storage.addAttribute(.foregroundColor, value: NSColor(Color.accent), range: bulletRange)
                storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 16, weight: .bold), range: bulletRange)
            }
            
            // Numbered lists
            let numberedListPattern = "^(\\d+)\\. "
            if let regex = try? NSRegularExpression(pattern: numberedListPattern) {
                if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: lineLength)) {
                    let numberRange = NSRange(location: currentLocation + match.range.location, length: match.range.length)
                    storage.addAttribute(.foregroundColor, value: NSColor(Color.accent), range: numberRange)
                    storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14, weight: .semibold), range: numberRange)
                }
            }
            
            // Checkboxes
            if line.contains("[ ]") {
                let checkboxPattern = "\\[ \\]"
                if let regex = try? NSRegularExpression(pattern: checkboxPattern) {
                    let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                    for match in matches {
                        let checkRange = NSRange(location: currentLocation + match.range.location, length: match.range.length)
                        storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText), range: checkRange)
                    }
                }
            }
            
            if line.contains("[x]") || line.contains("[X]") {
                let checkboxPattern = "\\[[xX]\\]"
                if let regex = try? NSRegularExpression(pattern: checkboxPattern) {
                    let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                    for match in matches {
                        let checkRange = NSRange(location: currentLocation + match.range.location, length: match.range.length)
                        storage.addAttribute(.foregroundColor, value: NSColor(Color.accent), range: checkRange)
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14, weight: .bold), range: checkRange)
                    }
                }
            }
            
            // Bold **text**
            styleInlineMarkdown(storage, in: line, at: currentLocation, pattern: "\\*\\*([^*]+)\\*\\*", 
                              font: NSFont.systemFont(ofSize: 15, weight: .bold), 
                              markerLength: 2, isCurrentLine: isCurrentLine)
            
            // Italic *text*
            styleInlineMarkdown(storage, in: line, at: currentLocation, pattern: "(?<!\\*)\\*([^*]+)\\*(?!\\*)", 
                              font: NSFontManager.shared.convert(NSFont.systemFont(ofSize: 15, weight: .regular), toHaveTrait: .italicFontMask), 
                              markerLength: 1, isCurrentLine: isCurrentLine)
            
            // Strikethrough ~~text~~
            let strikePattern = "~~([^~]+)~~"
            if let regex = try? NSRegularExpression(pattern: strikePattern) {
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                for match in matches {
                    if match.numberOfRanges >= 2 {
                        let contentRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                        storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
                        storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText), range: contentRange)
                        
                        styleMarker(storage, at: currentLocation + match.range.location, length: 2, isCurrentLine: isCurrentLine)
                        styleMarker(storage, at: currentLocation + match.range.location + match.range.length - 2, length: 2, isCurrentLine: isCurrentLine)
                    }
                }
            }
            
            // Inline code `code`
            let codePattern = "`([^`]+)`"
            if let regex = try? NSRegularExpression(pattern: codePattern) {
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                for match in matches {
                    if match.numberOfRanges >= 2 {
                        let fullMatchRange = NSRange(location: currentLocation + match.range.location, length: match.range.length)
                        let contentRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                        
                        // Style the content
                        storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold), range: contentRange)
                        storage.addAttribute(.foregroundColor, value: NSColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0), range: contentRange)
                        
                        // Add background with padding
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineSpacing = 2
                        storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullMatchRange)
                        storage.addAttribute(.backgroundColor, value: NSColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 0.12), range: fullMatchRange)
                        
                        // Style or hide markers
                        if !isCurrentLine {
                            let openMarker = NSRange(location: currentLocation + match.range.location, length: 1)
                            let closeMarker = NSRange(location: currentLocation + match.range.location + match.range.length - 1, length: 1)
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: openMarker)
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: closeMarker)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: openMarker)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: closeMarker)
                        } else {
                            let openMarker = NSRange(location: currentLocation + match.range.location, length: 1)
                            let closeMarker = NSRange(location: currentLocation + match.range.location + match.range.length - 1, length: 1)
                            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: openMarker)
                            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: closeMarker)
                        }
                    }
                }
            }
            
            // Links [text](url)
            let linkPattern = "\\[([^\\]]+)\\]\\(([^\\)]+)\\)"
            if let regex = try? NSRegularExpression(pattern: linkPattern) {
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                for match in matches {
                    if match.numberOfRanges >= 3 {
                        let textRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                        storage.addAttribute(.foregroundColor, value: NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0), range: textRange)
                        storage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 15, weight: .medium), range: textRange)
                        
                        if !isCurrentLine {
                            // Hide brackets and URL
                            let openBracket = NSRange(location: currentLocation + match.range.location, length: 1)
                            let closeBracket = NSRange(location: currentLocation + match.range(at: 1).location + match.range(at: 1).length, length: 1)
                            let urlPart = NSRange(location: currentLocation + match.range(at: 2).location - 1, length: match.range(at: 2).length + 2)
                            
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: openBracket)
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: closeBracket)
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: urlPart)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: openBracket)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: closeBracket)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: urlPart)
                        } else {
                            // Show URL in gray
                            let urlRange = NSRange(location: currentLocation + match.range(at: 2).location, length: match.range(at: 2).length)
                            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText), range: urlRange)
                        }
                    }
                }
            }
            
            // Wiki-style links [[text]]
            let wikiLinkPattern = "\\[\\[([^\\]]+)\\]\\]"
            if let regex = try? NSRegularExpression(pattern: wikiLinkPattern) {
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                for match in matches {
                    if match.numberOfRanges >= 2 {
                        let textRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                        storage.addAttribute(.foregroundColor, value: NSColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 1.0), range: textRange)
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 15, weight: .semibold), range: textRange)
                        
                        if !isCurrentLine {
                            // Hide brackets
                            let openBrackets = NSRange(location: currentLocation + match.range.location, length: 2)
                            let closeBrackets = NSRange(location: currentLocation + match.range.location + match.range.length - 2, length: 2)
                            
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: openBrackets)
                            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: closeBrackets)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: openBrackets)
                            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: closeBrackets)
                        } else {
                            // Show brackets in gray
                            let openBrackets = NSRange(location: currentLocation + match.range.location, length: 2)
                            let closeBrackets = NSRange(location: currentLocation + match.range.location + match.range.length - 2, length: 2)
                            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: openBrackets)
                            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: closeBrackets)
                        }
                    }
                }
            }
            
            // Hashtags #tag
            let hashtagPattern = "(?:^|\\s)(#[a-zA-Z0-9_-]+)"
            if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
                let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
                for match in matches {
                    if match.numberOfRanges >= 2 {
                        let tagRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                        storage.addAttribute(.foregroundColor, value: NSColor(red: 0.3, green: 0.8, blue: 0.6, alpha: 1.0), range: tagRange)
                        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 14, weight: .semibold), range: tagRange)
                    }
                }
            }
            
            currentLocation += lineLength + 1
        }
    }
    
    private func styleMarker(_ storage: NSTextStorage, at location: Int, length: Int, isCurrentLine: Bool) {
        let markerRange = NSRange(location: location, length: length)
        if !isCurrentLine {
            storage.addAttribute(.foregroundColor, value: NSColor.clear, range: markerRange)
            storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 1), range: markerRange)
        } else {
            storage.addAttribute(.foregroundColor, value: NSColor(Color.tertiaryText.opacity(0.5)), range: markerRange)
        }
    }
    
    private func styleInlineMarkdown(_ storage: NSTextStorage, in line: String, at currentLocation: Int, 
                                    pattern: String, font: NSFont, markerLength: Int, isCurrentLine: Bool) {
        let lineLength = (line as NSString).length
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: lineLength))
            for match in matches {
                if match.numberOfRanges >= 2 {
                    let contentRange = NSRange(location: currentLocation + match.range(at: 1).location, length: match.range(at: 1).length)
                    storage.addAttribute(.font, value: font, range: contentRange)
                    
                    styleMarker(storage, at: currentLocation + match.range.location, length: markerLength, isCurrentLine: isCurrentLine)
                    styleMarker(storage, at: currentLocation + match.range.location + match.range.length - markerLength, 
                              length: markerLength, isCurrentLine: isCurrentLine)
                }
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: MarkdownTextEditor
        var isUpdating = false
        private var lastCursorLine: Int = -1
        
        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating else { return }
            
            isUpdating = true
            parent.text = textView.string
            parent.isEditing = true
            
            // Apply styling immediately but prevent recursion
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isUpdating = false
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating else { return }
            
            // Only reapply if cursor moved to a different line
            let cursorLocation = textView.selectedRange().location
            let text = textView.string
            guard cursorLocation < text.count else { return }
            
            let currentLine = (text as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0)).location
            
            if currentLine != lastCursorLine {
                lastCursorLine = currentLine
                parent.applyMarkdownStyling(to: textView)
            }
        }
    }
}





// Rename Note View
struct RenameNoteView: View {
    @ObservedObject var appViewModel: AppViewModel
    let note: Note
    @State private var newName: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Note")
                .font(.system(size: 18, weight: .semibold))
            
            TextField("New name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Rename") {
                    Task {
                        await appViewModel.renameNote(note, to: newName)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newName.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
        .onAppear {
            newName = note.title
        }
    }
}

// Create Folder View
struct CreateFolderView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var folderName: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Folder")
                .font(.system(size: 18, weight: .semibold))
            
            TextField("Folder name", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    appViewModel.createNewFolder(name: folderName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(folderName.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// Quick Command Palette View
struct QuickCommandPalette: View {
    @ObservedObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredCommands: [QuickCommand] {
        let allCommands = [
            QuickCommand(title: "New Note", icon: "doc.badge.plus", action: {
                appViewModel.createNewNote()
                isPresented = false
            }),
            QuickCommand(title: "New Folder", icon: "folder.badge.plus", action: {
                appViewModel.presentedSheet = .createFolder
                isPresented = false
            }),
            QuickCommand(title: "Open Folder", icon: "folder", action: {
                isPresented = false
                // Trigger folder picker
            }),
            QuickCommand(title: "Settings", icon: "gearshape", action: {
                appViewModel.presentedSheet = .preferences
                isPresented = false
            }),
            QuickCommand(title: "Search Notes", icon: "magnifyingglass", action: {
                appViewModel.selectedSidebarItem = .search
                isPresented = false
            }),
            QuickCommand(title: "Close Note", icon: "xmark", action: {
                appViewModel.selectedNote = nil
                isPresented = false
            })
        ]
        
        if searchText.isEmpty {
            return allCommands
        }
        return allCommands.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(Color.secondaryText)
                
                TextField("Type a command...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.primaryBackground)
            
            Divider()
            
            // Commands list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredCommands) { command in
                        QuickCommandRow(command: command)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            isSearchFocused = true
        }
    }
}

struct QuickCommand: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

struct QuickCommandRow: View {
    let command: QuickCommand
    @State private var isHovered = false
    
    var body: some View {
        Button(action: command.action) {
            HStack(spacing: 12) {
                Image(systemName: command.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accent)
                    .frame(width: 24)
                
                Text(command.title)
                    .font(.system(size: 14))
                    .foregroundColor(Color.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovered ? Color.primaryBorder.opacity(0.3) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Settings View
struct SettingsView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    SettingsTabButton(title: "General", icon: "gearshape", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    SettingsTabButton(title: "Editor", icon: "doc.text", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    SettingsTabButton(title: "Files & Links", icon: "link", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    SettingsTabButton(title: "About", icon: "info.circle", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.horizontal, 12)
                
                Spacer()
            }
            .frame(width: 220)
            .background(Color.secondaryBackground)
            
            // Content area
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }
                
                ScrollView {
                    Group {
                        switch selectedTab {
                        case 0:
                            GeneralSettingsView()
                        case 1:
                            EditorSettingsView()
                        case 2:
                            FilesSettingsView()
                        case 3:
                            AboutView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.primaryBackground)
        }
        .frame(width: 800, height: 550)
    }
}

struct SettingsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? Color.accent : Color.secondaryText)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color.primaryText : Color.secondaryText)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accent.opacity(0.15) : (isHovered ? Color.primaryBorder.opacity(0.2) : Color.clear))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("spellCheck") private var spellCheck = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("General")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 20) {
                SettingRow(title: "Auto-save notes", description: "Automatically save changes as you type") {
                    Toggle("", isOn: $autoSave)
                        .labelsHidden()
                }
                
                Divider()
                
                SettingRow(title: "Spell check", description: "Check spelling while typing") {
                    Toggle("", isOn: $spellCheck)
                        .labelsHidden()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EditorSettingsView: View {
    @AppStorage("fontSize") private var fontSize = 15.0
    @AppStorage("lineHeight") private var lineHeight = 1.5
    @AppStorage("showLineNumbers") private var showLineNumbers = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Editor")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 20) {
                SettingRow(title: "Font Size", description: "\(Int(fontSize))px") {
                    Slider(value: $fontSize, in: 12...24, step: 1)
                        .frame(width: 200)
                }
                
                Divider()
                
                SettingRow(title: "Line Height", description: String(format: "%.1f", lineHeight)) {
                    Slider(value: $lineHeight, in: 1.0...2.5, step: 0.1)
                        .frame(width: 200)
                }
                
                Divider()
                
                SettingRow(title: "Show line numbers", description: "Display line numbers in editor") {
                    Toggle("", isOn: $showLineNumbers)
                        .labelsHidden()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FilesSettingsView: View {
    @AppStorage("defaultFileLocation") private var defaultFileLocation = "Root"
    @AppStorage("confirmDelete") private var confirmDelete = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Files & Links")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 20) {
                SettingRow(title: "Confirm before deleting", description: "Show confirmation dialog when deleting files") {
                    Toggle("", isOn: $confirmDelete)
                        .labelsHidden()
                }
                
                Divider()
                
                SettingRow(title: "Default location for new notes", description: "Where new notes are created") {
                    Picker("", selection: $defaultFileLocation) {
                        Text("Root folder").tag("Root")
                        Text("Current folder").tag("Current")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Helper view for consistent setting rows
struct SettingRow<Content: View>: View {
    let title: String
    let description: String
    let content: Content
    
    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color.primaryText)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.secondaryText)
            }
            
            Spacer()
            
            content
        }
        .padding(.vertical, 8)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About")
                .font(.system(size: 28, weight: .bold))
                .padding(.bottom, 32)
            
            VStack(alignment: .leading, spacing: 24) {
                // App Info
                HStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(Color.accent)
                        .frame(width: 64, height: 64)
                        .background(Color.accent.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strontium Notes")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Developer Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Developer")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.secondaryText)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.accent)
                            
                            Text("Sriram Ramnath")
                                .font(.system(size: 15))
                                .foregroundColor(Color.primaryText)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.secondaryText)
                            
                            Button(action: {
                                if let url = URL(string: "mailto:sriramramnath2011@gmail.com") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("sriramramnath2011@gmail.com")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.secondaryText)
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/sriramramnath") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("@sriramramnath on GitHub")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This App")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.secondaryText)
                        .textCase(.uppercase)
                    
                    Text("An Obsidian-inspired note-taking application for macOS with markdown support, WYSIWYM editing, and a clean, distraction-free interface.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VSCodeStyleView(appViewModel: AppViewModel())
        .preferredColorScheme(.dark)
}
