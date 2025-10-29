//
//  NoteEditorView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var editedContent: String = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let note = appViewModel.selectedNote {
                // Header with note info
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 12) {
                                Label(note.fileName, systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Label("Modified \(note.modifiedDate, style: .relative)", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if !note.tags.isEmpty {
                                    Label("\(note.tags.count) tags", systemImage: "tag")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Editor controls
                        HStack(spacing: 8) {
                            Button {
                                // TODO: Toggle preview mode
                            } label: {
                                Image(systemName: "eye")
                            }
                            .help("Preview")
                            
                            Button {
                                // TODO: Show note info
                            } label: {
                                Image(systemName: "info.circle")
                            }
                            .help("Note Info")
                            
                            Menu {
                                Button("Export as PDF") { }
                                Button("Export as HTML") { }
                                Divider()
                                Button("Duplicate Note") { }
                                Button("Move to Folder...") { }
                                Divider()
                                Button("Delete Note", role: .destructive) { }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .help("More Options")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    
                    Divider()
                }
                
                // Editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .onAppear {
                                editedContent = note.content
                            }
                            .onChange(of: editedContent) { _, _ in
                                isEditing = true
                            }
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                
                // Status bar
                HStack {
                    HStack(spacing: 16) {
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(characterCount) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !note.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(Array(note.tags.prefix(5)), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.orange.opacity(0.2))
                                        )
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if isEditing {
                        HStack(spacing: 8) {
                            Button("Revert") {
                                editedContent = note.content
                                isEditing = false
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Save") {
                                // TODO: Save the note
                                isEditing = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("Saved")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
            } else {
                // No note selected state
                VStack(spacing: 20) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 64))
                        .foregroundStyle(.quaternary)
                    
                    VStack(spacing: 8) {
                        Text("No Note Selected")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Text("Select a note from the sidebar or create a new one to start editing")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button("Create New Note") {
                        appViewModel.createNewNote()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 500)
    }
    
    private var wordCount: Int {
        editedContent
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private var characterCount: Int {
        editedContent.count
    }
}

#Preview {
    NoteEditorView(appViewModel: AppViewModel())
        .frame(width: 600, height: 500)
}