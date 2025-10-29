//
//  BacklinksView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct BacklinksView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var backlinks: [Note] {
        guard let selectedNote = appViewModel.selectedNote else { return [] }
        
        // Find notes that mention the selected note's title
        return appViewModel.mockNotes.filter { note in
            note.id != selectedNote.id &&
            (note.content.contains("[[\(selectedNote.title)]]") ||
             note.content.localizedCaseInsensitiveContains(selectedNote.title))
        }
    }
    
    private var unlinkedMentions: [Note] {
        guard let selectedNote = appViewModel.selectedNote else { return [] }
        
        // Find notes that mention the title but don't have wikilinks
        return appViewModel.mockNotes.filter { note in
            note.id != selectedNote.id &&
            note.content.localizedCaseInsensitiveContains(selectedNote.title) &&
            !note.content.contains("[[\(selectedNote.title)]]")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Backlinks")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if appViewModel.selectedNote != nil {
                    Text("\(backlinks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            if appViewModel.selectedNote == nil {
                // No note selected state
                VStack(spacing: 12) {
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No Note Selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Select a note to see its backlinks")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            } else if backlinks.isEmpty && unlinkedMentions.isEmpty {
                // No backlinks state
                VStack(spacing: 12) {
                    Image(systemName: "link.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No Backlinks")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("No other notes link to this note yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        // Linked references
                        if !backlinks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Linked References")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(backlinks.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                ForEach(backlinks) { note in
                                    BacklinkRowView(
                                        note: note,
                                        targetTitle: appViewModel.selectedNote?.title ?? "",
                                        isLinked: true
                                    ) {
                                        appViewModel.selectNote(note)
                                    }
                                }
                            }
                        }
                        
                        // Unlinked mentions
                        if !unlinkedMentions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Unlinked Mentions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(unlinkedMentions.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                ForEach(unlinkedMentions) { note in
                                    BacklinkRowView(
                                        note: note,
                                        targetTitle: appViewModel.selectedNote?.title ?? "",
                                        isLinked: false
                                    ) {
                                        appViewModel.selectNote(note)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct BacklinkRowView: View {
    let note: Note
    let targetTitle: String
    let isLinked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Note title with link indicator
                HStack(spacing: 6) {
                    Image(systemName: isLinked ? "link" : "link.badge.plus")
                        .font(.caption)
                        .foregroundStyle(isLinked ? .blue : .orange)
                    
                    Text(note.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Context snippet
                Text(contextSnippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var contextSnippet: String {
        let content = note.content
        let maxLength = 120
        
        // Find the target title in the content
        if let range = content.range(of: targetTitle, options: .caseInsensitive) {
            let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -40, limitedBy: content.startIndex) ?? content.startIndex)
            let end = min(content.endIndex, content.index(range.upperBound, offsetBy: 40, limitedBy: content.endIndex) ?? content.endIndex)
            
            var snippet = String(content[start..<end])
            
            // Clean up the snippet
            snippet = snippet.replacingOccurrences(of: "\n", with: " ")
            snippet = snippet.replacingOccurrences(of: "  ", with: " ")
            
            if start > content.startIndex {
                snippet = "..." + snippet
            }
            if end < content.endIndex {
                snippet = snippet + "..."
            }
            
            return snippet
        }
        
        // Fallback to beginning of content
        let snippet = String(content.prefix(maxLength))
        return snippet.count < content.count ? snippet + "..." : snippet
    }
}

#Preview {
    BacklinksView(appViewModel: AppViewModel())
        .frame(width: 300, height: 500)
}