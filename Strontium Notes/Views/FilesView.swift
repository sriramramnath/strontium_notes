//
//  FilesView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct FilesView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with actions
            HStack {
                Text("Files")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button(action: appViewModel.createNewNote) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                .help("Create New Note")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // File list - simple version
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(appViewModel.mockNotes) { note in
                        SimpleNoteRow(
                            note: note,
                            isSelected: appViewModel.selectedNote?.id == note.id,
                            onSelect: {
                                appViewModel.selectNote(note)
                            }
                        )
                    }
                    
                    if appViewModel.mockNotes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            
                            Text("No notes yet")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button("Create your first note") {
                                appViewModel.createNewNote()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }
}

struct SimpleNoteRow: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .accent : .secondary)
                
                Text(note.title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .accent : .primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FolderRowView: View {
    let folder: Folder
    @ObservedObject var appViewModel: AppViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Folder header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    
                    Text(folder.name)
                        .font(.system(.body, design: .default))
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Folder contents
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(appViewModel.mockNotes.filter { $0.filePath.hasPrefix(folder.path + "/") }) { note in
                        NoteRowView(
                            note: note,
                            isSelected: appViewModel.selectedNote?.id == note.id,
                            indentLevel: 1
                        ) {
                            appViewModel.selectNote(note)
                        }
                    }
                }
            }
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let isSelected: Bool
    let indentLevel: Int
    let action: () -> Void
    
    init(note: Note, isSelected: Bool, indentLevel: Int = 0, action: @escaping () -> Void) {
        self.note = note
        self.isSelected = isSelected
        self.indentLevel = indentLevel
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Indentation
                if indentLevel > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: CGFloat(indentLevel * 16))
                }
                
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                
                Text(note.title)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)
                
                Spacer()
                
                // Tags indicator
                if !note.tags.isEmpty {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

#Preview {
    FilesView(appViewModel: AppViewModel())
        .frame(width: 300, height: 400)
}