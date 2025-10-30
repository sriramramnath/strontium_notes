//
//  EnhancedBacklinksView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct EnhancedBacklinksView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    private var backlinks: [Backlink] {
        guard let selectedNote = appViewModel.selectedNote else { return [] }
        return appViewModel.getBacklinks(for: selectedNote)
    }
    
    private var outgoingLinks: [String] {
        guard let selectedNote = appViewModel.selectedNote else { return [] }
        return selectedNote.getLinks()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text("Connections")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    if let selectedNote = appViewModel.selectedNote {
                        Text(selectedNote.title)
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.tertiaryBackground)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
            
            if appViewModel.selectedNote == nil {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.tertiaryText)
                    
                    Text("Select a note to see connections")
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                    
                    Text("Backlinks and outgoing links will appear here")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Outgoing Links Section
                        if !outgoingLinks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.accent)
                                    
                                    Text("Outgoing Links")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(outgoingLinks.count)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.tertiaryText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.tertiaryBackground)
                                        )
                                }
                                
                                ForEach(outgoingLinks, id: \.self) { linkTitle in
                                    OutgoingLinkRowView(
                                        linkTitle: linkTitle,
                                        appViewModel: appViewModel
                                    )
                                }
                            }
                        }
                        
                        // Backlinks Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.down.left")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accent)
                                
                                Text("Backlinks")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Text("\(backlinks.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.tertiaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.tertiaryBackground)
                                    )
                            }
                            
                            if backlinks.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "link.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.tertiaryText)
                                    
                                    Text("No backlinks yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondaryText)
                                    
                                    Text("Other notes that link to this note will appear here")
                                        .font(.system(size: 11))
                                        .foregroundColor(.tertiaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(backlinks) { backlink in
                                    if let sourceNote = appViewModel.mockNotes.first(where: { $0.id == backlink.sourceNoteID }) {
                                        EnhancedBacklinkRowView(
                                            note: sourceNote,
                                            appViewModel: appViewModel
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.primaryBackground)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.selectedNote?.id)
    }
}

struct OutgoingLinkRowView: View {
    let linkTitle: String
    @ObservedObject var appViewModel: AppViewModel
    
    @State private var isHovered = false
    
    private var linkedNote: Note? {
        appViewModel.mockNotes.first { $0.title == linkTitle }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Link icon
            Image(systemName: linkedNote != nil ? "doc.text" : "doc.badge.plus")
                .font(.system(size: 14))
                .foregroundColor(linkedNote != nil ? .accent : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(linkTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(linkedNote != nil ? .primaryText : .orange)
                
                if linkedNote == nil {
                    Text("Note doesn't exist - click to create")
                        .font(.system(size: 11))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
            
            Spacer()
            
            if isHovered {
                Button {
                    if let note = linkedNote {
                        appViewModel.selectedNote = note
                    } else {
                        // Create new note with this title
                        let newNote = Note(
                            filePath: "\(linkTitle).md",
                            title: linkTitle,
                            content: "# \(linkTitle)\n\n"
                        )
                        appViewModel.mockNotes.append(newNote)
                        appViewModel.selectedNote = newNote
                    }
                    HapticManager.shared.mediumImpact()
                } label: {
                    Image(systemName: linkedNote != nil ? "arrow.right" : "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.accent)
                }
                .buttonStyle(GentleButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.tertiaryBackground : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let note = linkedNote {
                appViewModel.selectedNote = note
            } else {
                // Create new note
                let newNote = Note(
                    filePath: "\(linkTitle).md",
                    title: linkTitle,
                    content: "# \(linkTitle)\n\n"
                )
                appViewModel.mockNotes.append(newNote)
                appViewModel.selectedNote = newNote
            }
            HapticManager.shared.mediumImpact()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct EnhancedBacklinkRowView: View {
    let note: Note
    @ObservedObject var appViewModel: AppViewModel
    
    @State private var isHovered = false
    @State private var showContext = false
    
    private var linkContext: String {
        // Find the context around the link
        let content = note.content
        let targetTitle = appViewModel.selectedNote?.title ?? ""
        let linkPattern = "\\[\\[\(NSRegularExpression.escapedPattern(for: targetTitle))\\]\\]"
        
        if let regex = try? NSRegularExpression(pattern: linkPattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
            let matchRange = Range(match.range, in: content)!
            let contextStart = content.index(matchRange.lowerBound, offsetBy: -50, limitedBy: content.startIndex) ?? content.startIndex
            let contextEnd = content.index(matchRange.upperBound, offsetBy: 50, limitedBy: content.endIndex) ?? content.endIndex
            return String(content[contextStart..<contextEnd])
        }
        
        return String(content.prefix(100))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Note icon
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.accent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: 8) {
                        Text("\(note.wordCount) words")
                            .font(.system(size: 11))
                            .foregroundColor(.tertiaryText)
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.tertiaryText)
                        
                        Text(note.modifiedDate, style: .relative)
                            .font(.system(size: 11))
                            .foregroundColor(.tertiaryText)
                    }
                }
                
                Spacer()
                
                if isHovered {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showContext.toggle()
                        }
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: showContext ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.accent)
                    }
                    .buttonStyle(GentleButtonStyle())
                    
                    Button {
                        appViewModel.selectedNote = note
                        HapticManager.shared.mediumImpact()
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.accent)
                    }
                    .buttonStyle(GentleButtonStyle())
                }
            }
            
            // Context preview
            if showContext {
                Text(linkContext)
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.tertiaryBackground)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.tertiaryBackground : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appViewModel.selectedNote = note
            HapticManager.shared.selectionChanged()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    EnhancedBacklinksView(appViewModel: AppViewModel())
}