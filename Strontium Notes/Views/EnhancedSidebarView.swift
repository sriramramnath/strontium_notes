//
//  EnhancedSidebarView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct EnhancedSidebarView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var draggedNote: Note?
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var contextMenuLocation: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and controls
            headerView
            
            Divider()
            
            // Folder and notes list
            ScrollView {
                LazyVStack(spacing: 2) {
                    // Root level folders and notes
                    folderTreeView(parentId: nil)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Footer with sort options
            footerView
        }
        .background(Color.secondaryBackground)
        .contextMenu {
            contextMenuItems(for: nil)
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                appViewModel.createNewFolder(name: newFolderName.isEmpty ? "New Folder" : newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Title and new note button
            HStack {
                Text("Notes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        appViewModel.createNewNote()
                    }
                    HapticManager.shared.mediumImpact()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accent)
                        )
                }
                .buttonStyle(BouncyButtonStyle())
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)
                
                TextField("Search notes...", text: $appViewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                
                if !appViewModel.searchText.isEmpty {
                    Button {
                        appViewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.tertiaryBackground)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
    
    private var footerView: some View {
        HStack {
            Menu {
                ForEach(SortOption.allCases, id: \.rawValue) { option in
                    Button {
                        appViewModel.sortOption = option
                        HapticManager.shared.lightImpact()
                    } label: {
                        HStack {
                            Image(systemName: option.systemImage)
                            Text(option.rawValue)
                            if appViewModel.sortOption == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: appViewModel.sortOption.systemImage)
                        .font(.system(size: 11))
                    Text("Sort")
                        .font(.system(size: 11))
                }
                .foregroundColor(.tertiaryText)
            }
            .menuStyle(.borderlessButton)
            
            Spacer()
            
            Text("\(appViewModel.filteredNotes.count) notes")
                .font(.system(size: 11))
                .foregroundColor(.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func folderTreeView(parentId: UUID?) -> AnyView {
        return AnyView(
            Group {
                // Folders first
                ForEach(appViewModel.getSubfolders(of: parentId)) { folder in
                    VStack(alignment: .leading, spacing: 0) {
                        EnhancedFolderRowView(
                            folder: folder,
                            appViewModel: appViewModel,
                            onToggleExpansion: {
                                appViewModel.toggleFolderExpansion(folder)
                            },
                            onRename: { newName in
                                appViewModel.renameFolder(folder, to: newName)
                            },
                            onDelete: {
                                appViewModel.deleteFolder(folder)
                            },
                            onCreateNote: {
                                appViewModel.createNewNote(in: folder.id)
                            },
                            onCreateFolder: {
                                showingNewFolderAlert = true
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        
                        // Show folder contents if expanded
                        if folder.isExpanded {
                            folderTreeView(parentId: folder.id)
                                .padding(.leading, 16)
                                .transition(.slide)
                        }
                    }
                }
                
                // Notes in current folder
                ForEach(appViewModel.filteredNotes) { note in
                    EnhancedNoteRowView(
                        note: note,
                        appViewModel: appViewModel,
                        onRename: { newTitle in
                            Task {
                                await appViewModel.renameNote(note, to: newTitle)
                            }
                        },
                        onDelete: {
                            Task {
                                await appViewModel.deleteNote(note)
                            }
                        }
                    )
                    // TODO: Add drag and drop support when Note conforms to Transferable
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        )
    }
    
    private func contextMenuItems(for folder: Folder?) -> some View {
        Group {
            Button {
                if let folder = folder {
                    appViewModel.createNewNote(in: folder.id)
                } else {
                    appViewModel.createNewNote()
                }
                HapticManager.shared.mediumImpact()
            } label: {
                Label("New Note", systemImage: "doc.badge.plus")
            }
            
            Button {
                showingNewFolderAlert = true
                HapticManager.shared.mediumImpact()
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
            
            if let folder = folder {
                Divider()
                
                Button {
                    appViewModel.renameFolder(folder, to: "Renamed Folder")
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    appViewModel.deleteFolder(folder)
                    HapticManager.shared.heavyImpact()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}