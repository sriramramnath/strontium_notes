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
    
    var body: some View {
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
                ActivityBarIcon(icon: "gearshape.fill", isSelected: false) {
                    // Settings action
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondaryBackground)
    }
}

struct ActivityBarIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : Color.tertiaryText)
                .frame(width: 48, height: 48)
                .background(isSelected ? Color.primaryBackground : Color.clear)
                .overlay(
                    Rectangle()
                        .fill(Color.accent)
                        .frame(width: 2)
                        .opacity(isSelected ? 1 : 0),
                    alignment: .leading
                )
        }
        .buttonStyle(.plain)
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.secondaryText)
                    .textCase(.uppercase)
                
                Spacer()
                
                if appViewModel.selectedSidebarItem == .files {
                    Button(action: { appViewModel.createNewNote() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(Color.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.secondaryBackground)
            
            Divider()
                .background(Color.primaryBorder)
            
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

// VS Code-style File Tree
struct VSCodeFileTree: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var expandedFolders: Set<String> = ["root"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Vault name as root
            VSCodeTreeItem(
                icon: "folder.fill",
                title: "Strontium Notes",
                isExpanded: expandedFolders.contains("root"),
                level: 0,
                onToggle: {
                    if expandedFolders.contains("root") {
                        expandedFolders.remove("root")
                    } else {
                        expandedFolders.insert("root")
                    }
                }
            )
            
            if expandedFolders.contains("root") {
                ForEach(appViewModel.mockNotes) { note in
                    VSCodeFileItem(
                        note: note,
                        isSelected: appViewModel.selectedNote?.id == note.id,
                        level: 1,
                        onSelect: {
                            appViewModel.selectNote(note)
                        }
                    )
                }
            }
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
    let note: Note
    let isSelected: Bool
    let level: Int
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondaryText)
                
                Text(note.title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : Color.primaryText)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level * 12 + 8))
            .padding(.vertical, 4)
            .background(isSelected ? Color.primaryBorder : (isHovered ? Color.primaryBackground : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Placeholder views for other sidebar items
struct VSCodeSearchView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack {
            Text("Search")
                .foregroundColor(Color.secondaryText)
        }
        .padding()
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

// VS Code-style Editor
struct VSCodeEditor: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var editedContent: String = ""
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let note = appViewModel.selectedNote {
                // Tab bar
                HStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundColor(Color.secondaryText)
                        
                        Text(note.title)
                            .font(.system(size: 13))
                            .foregroundColor(Color.primaryText)
                        
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(Color.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primaryBackground)
                    
                    Spacer()
                }
                .background(Color.secondaryBackground)
                
                Divider()
                    .background(Color.primaryBorder)
                
                // Editor content
                VSCodeMarkdownPreview(content: editedContent)
                    .onAppear {
                        editedContent = note.content
                    }
                    .onChange(of: appViewModel.selectedNote?.id) { _, _ in
                        if let note = appViewModel.selectedNote {
                            editedContent = note.content
                        }
                    }
                
                // Status bar
                HStack {
                    Text("Markdown")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondaryText)
                    
                    Spacer()
                    
                    Text("\(editedContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) words")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondaryText)
                    
                    Text("\(editedContent.count) characters")
                        .font(.system(size: 11))
                        .foregroundColor(Color.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.accent.opacity(0.1))
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(Color.tertiaryText)
                    
                    Text("No file selected")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.primaryBackground)
    }
}

// Markdown Preview
struct VSCodeMarkdownPreview: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(parseMarkdown(content), id: \.id) { block in
                    renderBlock(block)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("# ") {
                blocks.append(MarkdownBlock(type: .h1, content: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                blocks.append(MarkdownBlock(type: .h2, content: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                blocks.append(MarkdownBlock(type: .h3, content: String(line.dropFirst(4))))
            } else if !line.isEmpty {
                blocks.append(MarkdownBlock(type: .paragraph, content: line))
            }
        }
        
        return blocks
    }
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block.type {
        case .h1:
            Text(block.content)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.primaryText)
        case .h2:
            Text(block.content)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color.primaryText)
        case .h3:
            Text(block.content)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.primaryText)
        case .paragraph:
            Text(block.content)
                .font(.system(size: 14))
                .foregroundColor(Color.primaryText)
                .lineSpacing(4)
        }
    }
}

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    let content: String
    
    enum BlockType {
        case h1, h2, h3, paragraph
    }
}

#Preview {
    VSCodeStyleView(appViewModel: AppViewModel())
        .preferredColorScheme(.dark)
}
