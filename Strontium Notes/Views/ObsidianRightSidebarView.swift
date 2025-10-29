//
//  ObsidianRightSidebarView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianRightSidebarView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedTab: RightSidebarTab = .backlinks
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HStack(spacing: 0) {
                ForEach(RightSidebarTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Rectangle()
                                .fill(selectedTab == tab ? Color.gray.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Close sidebar button
                Button {
                    appViewModel.showRightSidebar = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }
            .padding(.vertical, 8)
            .background(Color.black)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // Content
            Group {
                switch selectedTab {
                case .backlinks:
                    ObsidianBacklinksView(appViewModel: appViewModel)
                case .outline:
                    ObsidianOutlineView(appViewModel: appViewModel)
                case .tags:
                    ObsidianTagsView(appViewModel: appViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
    }
}

enum RightSidebarTab: String, CaseIterable {
    case backlinks = "Backlinks"
    case outline = "Outline"
    case tags = "Tags"
    
    var systemImage: String {
        switch self {
        case .backlinks: return "link"
        case .outline: return "list.bullet"
        case .tags: return "tag"
        }
    }
}

struct ObsidianBacklinksView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var backlinks: [Note] {
        guard let selectedNote = appViewModel.selectedNote else { return [] }
        
        return appViewModel.mockNotes.filter { note in
            note.id != selectedNote.id &&
            note.content.contains(selectedNote.title)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appViewModel.selectedNote == nil {
                VStack(spacing: 12) {
                    Image(systemName: "link")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No note selected")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if backlinks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No backlinks found")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text("No other notes link to this note")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(backlinks) { note in
                            ObsidianBacklinkRowView(
                                note: note,
                                targetTitle: appViewModel.selectedNote?.title ?? ""
                            ) {
                                appViewModel.selectNote(note)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
    }
}

struct ObsidianBacklinkRowView: View {
    let note: Note
    let targetTitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    Text(note.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Text(contextSnippet)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.leading, 17)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var contextSnippet: String {
        let content = note.content.replacingOccurrences(of: "\n", with: " ")
        if let range = content.range(of: targetTitle, options: .caseInsensitive) {
            let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -30, limitedBy: content.startIndex) ?? content.startIndex)
            let end = min(content.endIndex, content.index(range.upperBound, offsetBy: 30, limitedBy: content.endIndex) ?? content.endIndex)
            return "..." + String(content[start..<end]) + "..."
        }
        return String(content.prefix(80))
    }
}

struct ObsidianOutlineView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var headings: [HeadingItem] {
        guard let note = appViewModel.selectedNote else { return [] }
        
        let lines = note.content.components(separatedBy: .newlines)
        var headings: [HeadingItem] = []
        
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("# ") {
                headings.append(HeadingItem(id: index, text: String(line.dropFirst(2)), level: 1))
            } else if line.hasPrefix("## ") {
                headings.append(HeadingItem(id: index, text: String(line.dropFirst(3)), level: 2))
            } else if line.hasPrefix("### ") {
                headings.append(HeadingItem(id: index, text: String(line.dropFirst(4)), level: 3))
            }
        }
        
        return headings
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if appViewModel.selectedNote == nil {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No note selected")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if headings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No headings found")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(headings) { heading in
                            ObsidianHeadingRowView(heading: heading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
    }
}

struct ObsidianHeadingRowView: View {
    let heading: HeadingItem
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: CGFloat((heading.level - 1) * 12))
            
            Text(heading.text)
                .font(.system(size: heading.level == 1 ? 12 : 11, weight: heading.level == 1 ? .medium : .regular))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }
}

struct HeadingItem: Identifiable {
    let id: Int
    let text: String
    let level: Int
}

struct ObsidianTagsView: View {
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
        VStack(alignment: .leading, spacing: 0) {
            if allTags.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No tags found")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(allTags.keys.sorted(), id: \.self) { tag in
                            ObsidianTagRowView(
                                tag: tag,
                                count: allTags[tag] ?? 0
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
    }
}

struct ObsidianTagRowView: View {
    let tag: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text("#\(tag)")
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    ObsidianRightSidebarView(appViewModel: AppViewModel())
        .frame(width: 280, height: 600)
}