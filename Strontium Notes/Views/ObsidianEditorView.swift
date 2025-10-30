//
//  ObsidianEditorView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianEditorView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var editedContent: String = ""
    @State private var isEditing = false
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let note = appViewModel.selectedNote {
                headerBarView(for: note)
                dividerView
                editorContentView(for: note)
                statusBarView
            }
        }
        .background(Color.primaryBackground)
    }
    
    private func headerBarView(for note: Note) -> some View {
        HStack(spacing: 12) {
            breadcrumbView(for: note)
            Spacer()
            editorModeControls
            moreOptionsMenu
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.primaryBackground)
    }
    
    private func breadcrumbView(for note: Note) -> some View {
        HStack(spacing: 4) {
            Text("Strontium Notes")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)
            
            Text(note.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryText)
        }
    }
    
    private var editorModeControls: some View {
        HStack(spacing: 2) {
            ForEach([EditorMode.wysiwym, EditorMode.edit, EditorMode.preview, EditorMode.livePreview], id: \.rawValue) { mode in
                Button {
                    appViewModel.editorMode = mode
                    if mode == .edit {
                        isTextEditorFocused = true
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 11))
                            .foregroundColor(appViewModel.editorMode == mode ? .white : .secondaryText)
                        
                        Text(mode.displayName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(appViewModel.editorMode == mode ? .white : .secondaryText)
                    }
                    .frame(width: 50, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(appViewModel.editorMode == mode ? Color.accent : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primaryBorder, lineWidth: 1)
                )
        )
        .padding(2)
    }
    
    private var moreOptionsMenu: some View {
        Menu {
            Button("Export as PDF") { }
            Button("Export as HTML") { }
            Divider()
            Button("Delete note", role: .destructive) { }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
                .frame(width: 20, height: 20)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
    
    private var dividerView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 1)
    }
    
    private func editorContentView(for note: Note) -> some View {
        Group {
            switch appViewModel.editorMode {
            case .wysiwym:
                // Clean Notion-style editor
                NotionEditor(text: $editedContent, isEditing: $isEditing) { newText in
                    editedContent = newText
                    Task {
                        await saveNoteAsync()
                    }
                }
            case .edit:
                // Simple text editor
                TextEditor(text: $editedContent)
                    .font(.system(size: 16))
                    .foregroundColor(.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.primaryBackground)
                    .padding()
                    .focused($isTextEditorFocused)
                    .onChange(of: editedContent) { _, _ in
                        isEditing = true
                    }
                    .onChangeDebounced(of: editedContent, delay: 0.15) { newContent in
                        Task {
                            await saveNoteAsync()
                        }
                    }
            case .preview:
                ScrollView {
                    Text(editedContent)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.primaryBackground)
                .onTapGesture {
                    appViewModel.editorMode = .edit
                    isTextEditorFocused = true
                }
            case .livePreview:
                // Simple text editor for now
                TextEditor(text: $editedContent)
                    .font(.system(size: 16))
                    .foregroundColor(.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.primaryBackground)
                    .padding()
                    .focused($isTextEditorFocused)
                    .onChange(of: editedContent) { _, _ in
                        isEditing = true
                    }
                    .onChangeDebounced(of: editedContent, delay: 0.15) { newContent in
                        Task {
                            await saveNoteAsync()
                        }
                    }
            }
        }
        .onAppear {
            editedContent = note.content
        }
        .onChange(of: appViewModel.selectedNote?.id) { _, _ in
            if let note = appViewModel.selectedNote {
                editedContent = note.content
                isEditing = false
            }
        }
    }
    
    private func saveNote() {
        Task {
            await saveNoteAsync()
        }
    }
    
    private func saveNoteAsync() async {
        guard let note = appViewModel.selectedNote else { return }
        
        // Update the note content
        let updatedNote = Note(
            filePath: note.filePath,
            title: note.title,
            content: editedContent
        )
        
        // Save through the app view model
        await appViewModel.saveNote(updatedNote)
        isEditing = false
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
    
    private var statusBarView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("\(wordCount) words")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
                
                Text("\(characterCount) chars")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
            
            Spacer()
            
            if isEditing {
                HStack(spacing: 8) {
                    Button("Revert") {
                        if let note = appViewModel.selectedNote {
                            editedContent = note.content
                            isEditing = false
                        }
                    }
                    .buttonStyle(ObsidianGrayButtonStyle(size: .small))
                    
                    Button("Save") {
                        saveNote()
                    }
                    .buttonStyle(ObsidianRedButtonStyle(size: .small))
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("All changes saved")
                        .font(.system(size: 11))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.secondaryBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.primaryBorder)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

struct ObsidianTextEditor: View {
    @Binding var content: String
    @Binding var isEditing: Bool
    @FocusState.Binding var isTextEditorFocused: Bool
    let onSave: () -> Void
    
    var body: some View {
        ScrollView {
            TextEditor(text: $content)
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(.white)
                .focused($isTextEditorFocused)
                .onSubmit {
                    // Simple submit handling - user can use Cmd+S or the Save button
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .background(Color.black)
    }
}

struct ObsidianPreviewView: View {
    let content: String
    let onTap: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ObsidianMarkdownRenderer(content: content)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .background(Color.black)
    }
}

struct ObsidianLivePreviewEditor: View {
    @Binding var content: String
    @Binding var isEditing: Bool
    let onSave: () -> Void
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Editor pane
            VStack(spacing: 0) {
                HStack {
                    Text("Edit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                ScrollView {
                    TextEditor(text: $content)
                        .font(.system(size: 14, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .focused($isTextEditorFocused)
                        .onSubmit {
                            // Simple submit handling - user can use Cmd+S or the Save button
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                .background(Color.black)
            }
            
            // Vertical divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // Preview pane
            VStack(spacing: 0) {
                HStack {
                    Text("Preview")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ObsidianMarkdownRenderer(content: content)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black)
            }
        }
        .background(Color.black)
    }
}

struct ObsidianMarkdownRenderer: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdownLines(content), id: \.id) { line in
                renderLine(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func parseMarkdownLines(_ markdown: String) -> [MarkdownLine] {
        let lines = markdown.components(separatedBy: .newlines)
        return lines.enumerated().map { index, line in
            MarkdownLine(id: index, content: line, type: getLineType(line))
        }
    }
    
    private func getLineType(_ line: String) -> MarkdownLineType {
        if line.hasPrefix("# ") {
            return .h1
        } else if line.hasPrefix("## ") {
            return .h2
        } else if line.hasPrefix("### ") {
            return .h3
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            return .bullet
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            return .empty
        } else {
            return .paragraph
        }
    }
    
    @ViewBuilder
    private func renderLine(_ line: MarkdownLine) -> some View {
        switch line.type {
        case .h1:
            Text(String(line.content.dropFirst(2)))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 4)
        case .h2:
            Text(String(line.content.dropFirst(3)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.vertical, 3)
        case .h3:
            Text(String(line.content.dropFirst(4)))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.vertical, 2)
        case .bullet:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text(String(line.content.dropFirst(2)))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Spacer()
            }
        case .paragraph:
            if !line.content.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(renderInlineMarkdown(line.content))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        case .empty:
            Spacer()
                .frame(height: 8)
        }
    }
    
    private func renderInlineMarkdown(_ text: String) -> String {
        let rendered = text
        
        // Simple inline rendering - preserve markdown for now
        // TODO: Implement proper markdown rendering with AttributedString
        
        return rendered
    }
}

struct MarkdownLine {
    let id: Int
    let content: String
    let type: MarkdownLineType
}

enum MarkdownLineType {
    case h1, h2, h3, bullet, paragraph, empty
}

#Preview {
    ObsidianEditorView(appViewModel: AppViewModel())
        .frame(width: 800, height: 600)
}