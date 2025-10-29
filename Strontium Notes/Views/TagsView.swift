//
//  TagsView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct TagsView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var allTags: [String: Int] {
        var tagCounts: [String: Int] = [:]
        
        for note in appViewModel.mockNotes {
            for tag in note.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(allTags.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Tags list
            if allTags.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No tags found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add #tags to your notes to organize them")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(allTags.keys.sorted(), id: \.self) { tag in
                            TagRowView(
                                tag: tag,
                                count: allTags[tag] ?? 0,
                                appViewModel: appViewModel
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct TagRowView: View {
    let tag: String
    let count: Int
    @ObservedObject var appViewModel: AppViewModel
    @State private var isHovered = false
    
    var body: some View {
        Button {
            // Filter notes by this tag
            appViewModel.selectedSidebarItem = .search
            appViewModel.searchText = "tag:\(tag)"
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                
                Text(tag)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    TagsView(appViewModel: AppViewModel())
        .frame(width: 300, height: 400)
}