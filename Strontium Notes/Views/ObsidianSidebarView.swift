//
//  ObsidianSidebarView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianSidebarView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var isCollapsed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with vault name and controls
            HStack(spacing: ObsidianUI.smallSpacing) {
                Text("Strontium Notes")
                    .font(.system(size: ObsidianUI.bodyFont, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                // Vault actions
                Menu {
                    Button("Open vault...") {
                        appViewModel.openVault()
                    }
                    Button("Create new vault...") {
                        appViewModel.createNewVault()
                    }
                    Divider()
                    Button("Settings") {
                        appViewModel.presentedSheet = .preferences
                    }
                    Button("About") {
                        appViewModel.presentedSheet = .about
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: ObsidianUI.smallFont))
                        .foregroundColor(.secondaryText)
                        .frame(width: ObsidianUI.largeIcon, height: ObsidianUI.largeIcon)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, ObsidianUI.largeSpacing)
            .padding(.vertical, ObsidianUI.mediumSpacing)
            .frame(height: ObsidianUI.sidebarHeaderHeight)
            .background(Color.secondaryBackground)
            
            // Divider
            Rectangle()
                .fill(Color.primaryBorder)
                .frame(height: ObsidianUI.thinBorder)
            
            if appViewModel.currentVault != nil {
                // Tab bar for different views
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach([SidebarItem.files, SidebarItem.search, SidebarItem.tags, SidebarItem.backlinks, SidebarItem.daily, SidebarItem.stats], id: \.rawValue) { item in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appViewModel.selectedSidebarItem = item
                            }
                            HapticManager.shared.selectionChanged()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.systemImage)
                                    .font(.system(size: 12))
                                Text(item.rawValue)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(appViewModel.selectedSidebarItem == item ? .white : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Rectangle()
                                    .fill(appViewModel.selectedSidebarItem == item ? Color.accent.opacity(0.3) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        // New note button
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            appViewModel.createNewNote()
                        }
                        HapticManager.shared.mediumImpact()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accent)
                                    .shadow(color: Color.accent.opacity(0.3), radius: 3, x: 0, y: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.secondaryBackground)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                // Content based on selected tab
                Group {
                    switch appViewModel.selectedSidebarItem {
                    case .files:
                        ObsidianFilesView(appViewModel: appViewModel)
                    case .search:
                        ObsidianSearchView(appViewModel: appViewModel)
                    case .tags:
                        TagsView(appViewModel: appViewModel)
                    case .backlinks:
                        BacklinksView(appViewModel: appViewModel)
                    case .daily:
                        DailyNotesPlaceholderView()
                    case .stats:
                        StatisticsView(appViewModel: appViewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: appViewModel.selectedSidebarItem)
            } else {
                // No vault state
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    
                    Text("No vault open")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Button("Open vault") {
                            appViewModel.openVault()
                        }
                        .buttonStyle(ObsidianRedButtonStyle())
                        
                        Button("Create new vault") {
                            appViewModel.createNewVault()
                        }
                        .buttonStyle(ObsidianGrayButtonStyle())
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black)
    }
}

struct ObsidianFilesView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(appViewModel.mockNotes) { note in
                    ObsidianFileRowView(
                        note: note,
                        isSelected: appViewModel.selectedNote?.id == note.id
                    ) {
                        appViewModel.selectNote(note)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color.secondaryBackground)
    }
}

struct ObsidianFileRowView: View {
    let note: Note
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundColor(isSelected ? .white : .secondaryText)
                .frame(width: 16)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            if isEditing {
                TextField("Note title", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .onSubmit {
                        finishEditing()
                    }
                    .onExitCommand {
                        cancelEditing()
                    }
            } else {
                Text(note.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : .primaryText)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            startEditing()
                        }
                    }
                    .onTapGesture(count: 1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            action()
                        }
                    }
            }
            
            Spacer()
            
            if isHovered && !isEditing {
                Menu {
                    Button("Rename") {
                        startEditing()
                    }
                    Button("Duplicate") {
                        // TODO: Implement duplicate
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        // TODO: Implement delete
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: 16, height: 16)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isSelected ? Color.red.opacity(0.8) :
                    isHovered ? Color.gray.opacity(0.15) : Color.clear
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func startEditing() {
        editedTitle = note.title
        isEditing = true
    }
    
    private func finishEditing() {
        // TODO: Save the new title
        isEditing = false
    }
    
    private func cancelEditing() {
        editedTitle = note.title
        isEditing = false
    }
}

struct ObsidianSearchView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var searchResults: [Note] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                TextField("Search...", text: $appViewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .onChange(of: appViewModel.searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Search results
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(searchResults) { note in
                        ObsidianSearchResultView(
                            note: note,
                            searchQuery: appViewModel.searchText,
                            isSelected: appViewModel.selectedNote?.id == note.id
                        ) {
                            appViewModel.selectNote(note)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .background(Color.black)
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchResults = appViewModel.mockNotes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query)
        }
    }
}

struct ObsidianSearchResultView: View {
    let note: Note
    let searchQuery: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 16)
                    
                    Text(note.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Text(contentSnippet)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.leading, 24)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.gray.opacity(0.3) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var contentSnippet: String {
        let content = note.content.replacingOccurrences(of: "\n", with: " ")
        return String(content.prefix(100))
    }
}

// Placeholder view for Daily Notes (to be implemented)
struct DailyNotesPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundColor(.secondaryText)
            
            Text("Daily Notes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryText)
            
            Text("Coming soon")
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

#Preview {
    ObsidianSidebarView(appViewModel: AppViewModel())
        .frame(width: 280, height: 600)
}