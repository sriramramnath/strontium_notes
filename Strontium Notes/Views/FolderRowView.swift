//
//  FolderRowView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct EnhancedFolderRowView: View {
    let folder: Folder
    @ObservedObject var appViewModel: AppViewModel
    let onToggleExpansion: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    let onCreateNote: () -> Void
    let onCreateFolder: () -> Void
    
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingName = ""
    
    private var isSelected: Bool {
        appViewModel.selectedFolderId == folder.id
    }
    
    private var expansionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onToggleExpansion()
            }
            HapticManager.shared.lightImpact()
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.tertiaryText)
                .rotationEffect(.degrees(folder.isExpanded ? 90 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: folder.isExpanded)
        }
        .buttonStyle(.plain)
        .frame(width: 16, height: 16)
    }
    
    private var folderBackground: some View {
        let fillColor = isSelected ? Color.accent.opacity(0.1) : Color.clear
        let strokeColor: Color
        if isSelected {
            strokeColor = Color.accent.opacity(0.3)
        } else if isHovered {
            strokeColor = Color.accent.opacity(0.1)
        } else {
            strokeColor = Color.clear
        }
        
        return RoundedRectangle(cornerRadius: 6)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }
    
    var body: some View {
        HStack(spacing: 8) {
            expansionButton
            
            // Folder icon
            Image(systemName: folder.isExpanded ? "folder.fill" : "folder")
                .font(.system(size: 14))
                .foregroundColor(.accent)
            
            // Folder name
            if isEditing {
                TextField("Folder name", text: $editingName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        onRename(editingName)
                        isEditing = false
                    }
                    .onAppear {
                        editingName = folder.name
                    }
            } else {
                Text(folder.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primaryText)
                    .onTapGesture(count: 2) {
                        isEditing = true
                        HapticManager.shared.lightImpact()
                    }
            }
            
            Spacer()
            
            // Note count
            if isHovered {
                Text("\(appViewModel.getNotesCount(in: folder.id))")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.tertiaryBackground)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(folderBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                appViewModel.selectedFolderId = appViewModel.selectedFolderId == folder.id ? nil : folder.id
            }
            HapticManager.shared.selectionChanged()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        // TODO: Add drag/drop support when Note conforms to Transferable
        .contextMenu {
            Button {
                onCreateNote()
            } label: {
                Label("New Note", systemImage: "doc.badge.plus")
            }
            
            Button {
                onCreateFolder()
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
            
            Divider()
            
            Button {
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    EnhancedFolderRowView(
        folder: Folder(name: "Sample Folder", path: "Sample Folder"),
        appViewModel: AppViewModel(),
        onToggleExpansion: {},
        onRename: { _ in },
        onDelete: {},
        onCreateNote: {},
        onCreateFolder: {}
    )
    .frame(width: 280)
    .padding()
}