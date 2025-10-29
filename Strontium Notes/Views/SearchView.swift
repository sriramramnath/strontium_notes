//
//  SearchView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var searchResults: [Note] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Search")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Search field
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search notes...", text: $appViewModel.searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: appViewModel.searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !appViewModel.searchText.isEmpty {
                        Button {
                            appViewModel.searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Search tips
                if appViewModel.searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Tips:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("• Use quotes for exact phrases")
                            Text("• tag:name to search by tag")
                            Text("• -word to exclude terms")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Search results
            if !appViewModel.searchText.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if searchResults.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                
                                Text("No results found")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text("Try different keywords or check your spelling")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(searchResults) { note in
                                SearchResultView(
                                    note: note,
                                    searchQuery: appViewModel.searchText,
                                    isSelected: appViewModel.selectedNote?.id == note.id
                                ) {
                                    appViewModel.selectNote(note)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            } else {
                Spacer()
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Simple search implementation for demo
        searchResults = appViewModel.mockNotes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

struct SearchResultView: View {
    let note: Note
    let searchQuery: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Title
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(note.tags.prefix(2)), id: \.self) { tag in
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
                        }
                    }
                }
                
                // Content snippet
                Text(contentSnippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                // File path
                Text(note.filePath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var contentSnippet: String {
        let content = note.content
        let maxLength = 150
        
        if content.count <= maxLength {
            return content
        }
        
        // Try to find the search query in the content for context
        if let range = content.range(of: searchQuery, options: .caseInsensitive) {
            let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -50, limitedBy: content.startIndex) ?? content.startIndex)
            let end = min(content.endIndex, content.index(range.upperBound, offsetBy: 50, limitedBy: content.endIndex) ?? content.endIndex)
            return "..." + String(content[start..<end]) + "..."
        }
        
        return String(content.prefix(maxLength)) + "..."
    }
}

#Preview {
    SearchView(appViewModel: AppViewModel())
        .frame(width: 300, height: 500)
}