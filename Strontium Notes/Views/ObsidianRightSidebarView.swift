//
//  ObsidianRightSidebarView.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

struct ObsidianRightSidebarView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var selectedTab: RightSidebarTab = .backlinks
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                ForEach(RightSidebarTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.title)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedTab == tab ? .accent : .secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Rectangle()
                                .fill(selectedTab == tab ? Color.accent.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.secondaryBackground)
            
            Rectangle()
                .fill(Color.primaryBorder)
                .frame(height: 1)
            
            // Content
            Group {
                switch selectedTab {
                case .backlinks:
                    BacklinksView(appViewModel: appViewModel)
                case .outline:
                    OutlineView(appViewModel: appViewModel)
                case .tags:
                    TagsView(appViewModel: appViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
        .background(Color.primaryBackground)
    }
}

enum RightSidebarTab: CaseIterable {
    case backlinks
    case outline
    case tags
    
    var title: String {
        switch self {
        case .backlinks: return "Links"
        case .outline: return "Outline"
        case .tags: return "Tags"
        }
    }
    
    var icon: String {
        switch self {
        case .backlinks: return "link"
        case .outline: return "list.bullet.indent"
        case .tags: return "tag"
        }
    }
}

struct OutlineView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var headers: [MarkdownHeader] {
        guard let note = appViewModel.selectedNote else { return [] }
        return MarkdownParser.extractHeaders(note.content)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Outline")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(headers.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Rectangle()
                .fill(Color.primaryBorder)
                .frame(height: 1)
            
            if headers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 32))
                        .foregroundColor(.secondaryText)
                    
                    Text("No headings")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                    
                    Text("Add # headings to see outline")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(headers) { header in
                            OutlineHeaderRow(header: header)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct OutlineHeaderRow: View {
    let header: MarkdownHeader
    @State private var isHovered = false
    
    var body: some View {
        Button {
            // TODO: Scroll to header in editor
        } label: {
            HStack(spacing: 8) {
                Text(header.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.leading, CGFloat((header.level - 1) * 12))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.secondaryBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ObsidianRightSidebarView(appViewModel: AppViewModel())
        .frame(width: 280, height: 600)
}
