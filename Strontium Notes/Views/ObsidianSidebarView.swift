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
            HStack(spacing: 8) {
                Text("Strontium Notes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
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
                        appViewModel.showingPreferences = true
                    }
                    Button("About") {
                        appViewModel.showingAbout = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            if appViewModel.currentVault != nil {
                // Tab bar for different views
                HStack(spacing: 0) {
                    ForEach([SidebarItem.files, SidebarItem.search], id: \.rawValue) { item in
                        Button {
                            appViewModel.selectedSidebarItem = item
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
                                    .fill(appViewModel.selectedSidebarItem == item ? Color.gray.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // New note button
                    Button {
                        appViewModel.createNewNote()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red)
                                    .shadow(color: Color.red.opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 8)
                .background(Color.black)
                
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
                    default:
                        ObsidianFilesView(appViewModel: appViewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .background(Color.black)
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
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 16)
            
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
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
                    .onTapGesture(count: 1) {
                        action()
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

#Preview {
    ObsidianSidebarView(appViewModel: AppViewModel())
        .frame(width: 280, height: 600)
}