//
//  NoteListView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notes")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: appViewModel.createNewNote) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Create New Note")
            }
            .padding()
            
            Divider()
            
            // Notes list
            if appViewModel.mockNotes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Notes Yet")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("Create your first note to get started")
                        .foregroundStyle(.tertiary)
                    
                    Button("Create Note") {
                        appViewModel.createNewNote()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(appViewModel.mockNotes) { note in
                            NoteListRowView(
                                note: note,
                                isSelected: appViewModel.selectedNote?.id == note.id
                            ) {
                                appViewModel.selectNote(note)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 300, maxWidth: 400)
    }
}

struct NoteListRowView: View {
    let note: Note
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and date
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(note.modifiedDate, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                // Content preview
                Text(contentPreview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Tags and metadata
                HStack {
                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(note.tags.prefix(3)), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.orange.opacity(0.2))
                                    )
                                    .foregroundStyle(.orange)
                            }
                            
                            if note.tags.count > 3 {
                                Text("+\(note.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Word count
                    Text("\(wordCount) words")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var contentPreview: String {
        let content = note.content
            .replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "## ", with: "")
            .replacingOccurrences(of: "### ", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return content.isEmpty ? "No content" : content
    }
    
    private var wordCount: Int {
        note.content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

#Preview {
    NoteListView(appViewModel: AppViewModel())
        .frame(width: 350, height: 600)
}