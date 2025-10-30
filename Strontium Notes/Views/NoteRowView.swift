//
//  NoteRowView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct EnhancedNoteRowView: View {
    let note: Note
    @ObservedObject var appViewModel: AppViewModel
    let onRename: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var showPreview = false
    
    private var isSelected: Bool {
        appViewModel.selectedNote?.id == note.id
    }
    
    private var noteTitleView: some View {
        Text(note.title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .accent : .primaryText)
            .lineLimit(1)
            .onTapGesture(count: 2) {
                isEditing = true
                HapticManager.shared.lightImpact()
            }
    }
    
    private var noteMetadataView: some View {
        HStack(spacing: 8) {
            Text("\(note.wordCount) words")
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)
            
            Text(note.modifiedDate, style: .relative)
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)
            
            if !note.tags.isEmpty {
                noteTagsView
            }
        }
    }
    
    private var noteTagsView: some View {
        HStack(spacing: 2) {
            ForEach(Array(note.tags.prefix(2)), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.system(size: 9))
                    .foregroundColor(.accent)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accent.opacity(0.1))
                    )
            }
            if note.tags.count > 2 {
                Text("+\(note.tags.count - 2)")
                    .font(.system(size: 9))
                    .foregroundColor(.tertiaryText)
            }
        }
    }
    
    private var noteBackground: some View {
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
            // Note icon
            Image(systemName: "doc.text")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // Note title
                if isEditing {
                    TextField("Note title", text: $editingTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium))
                        .onSubmit {
                            onRename(editingTitle)
                            isEditing = false
                        }
                        .onAppear {
                            editingTitle = note.title
                        }
                } else {
                    noteTitleView
                }
                
                // Note metadata
                if isHovered || isSelected {
                    noteMetadataView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(noteBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                appViewModel.selectedNote = note
            }
            HapticManager.shared.selectionChanged()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                if hovering {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if isHovered {
                            showPreview = true
                        }
                    }
                } else {
                    showPreview = false
                }
            }
        }
        .contextMenu {
            Button {
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                // Duplicate note
                appViewModel.createNewNote()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .popover(isPresented: $showPreview) {
            NotePreviewPopover(note: note)
        }
    }
}

struct NotePreviewView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primaryText)
            
            Text(note.content.prefix(100))
                .font(.system(size: 10))
                .foregroundColor(.secondaryText)
                .lineLimit(3)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondaryBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .frame(width: 200)
    }
}

struct NotePreviewPopover: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(note.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryText)
            
            ScrollView {
                Text(note.content)
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            
            HStack {
                Text("\(note.wordCount) words")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText)
                
                Spacer()
                
                Text("Modified \(note.modifiedDate, style: .relative)")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}

#Preview {
    let sampleNote = Note(
        filePath: "Sample.md",
        title: "Sample Note",
        content: "This is a sample note with some content to preview."
    )
    
    return EnhancedNoteRowView(
        note: sampleNote,
        appViewModel: AppViewModel(),
        onRename: { _ in },
        onDelete: {}
    )
    .frame(width: 280)
    .padding()
}