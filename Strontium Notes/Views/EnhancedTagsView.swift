//
//  EnhancedTagsView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct EnhancedTagsView: View {
    @ObservedObject var appViewModel: AppViewModel
    @State private var searchText = ""
    
    var filteredTags: [(String, Int)] {
        let tags = appViewModel.allTags
        if searchText.isEmpty {
            return tags.sorted { $0.value > $1.value }
        } else {
            return tags.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.value > $1.value }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text("Tags")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Text("\(appViewModel.allTags.count) tags")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.tertiaryBackground)
                        )
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.tertiaryText)
                    
                    TextField("Search tags...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.tertiaryBackground)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
            
            // Tags list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTags, id: \.0) { tagPair in
                        EnhancedTagRowView(
                            tag: tagPair.0,
                            appViewModel: appViewModel,
                            isSelected: false,
                            onToggle: {
                                // TODO: Implement tag selection
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // Selected tags footer
            if !appViewModel.selectedTags.isEmpty {
                Divider()
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Filtered by tags:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appViewModel.selectedTags.removeAll()
                            }
                            HapticManager.shared.lightImpact()
                        } label: {
                            Text("Clear all")
                                .font(.system(size: 12))
                                .foregroundColor(.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Selected tags
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(appViewModel.selectedTags), id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                
                                Button {
                                    _ = withAnimation(.easeInOut(duration: 0.2)) {
                                        appViewModel.selectedTags.remove(tag)
                                    }
                                    HapticManager.shared.lightImpact()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accent)
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.primaryBackground)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.selectedTags)
    }
    
    private func toggleTagSelection(_ tag: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if appViewModel.selectedTags.contains(tag) {
                appViewModel.selectedTags.remove(tag)
            } else {
                appViewModel.selectedTags.insert(tag)
            }
        }
        HapticManager.shared.selectionChanged()
    }
}

struct EnhancedTagRowView: View {
    let tag: String
    @ObservedObject var appViewModel: AppViewModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    private var notesWithTag: [Note] {
        appViewModel.mockNotes.filter { $0.tags.contains(tag) }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Tag icon and name
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .accent : .secondaryText)
                
                Text(tag)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .accent : .primaryText)
            }
            
            Spacer()
            
            // Note count
            Text("\(notesWithTag.count)")
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accent.opacity(0.1) : Color.tertiaryBackground)
                )
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accent.opacity(0.05) : (isHovered ? Color.tertiaryBackground : Color.clear))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.accent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            Button {
                // Show all notes with this tag
                appViewModel.selectedTags = [tag]
                appViewModel.selectedSidebarItem = .files
            } label: {
                Label("Show notes with this tag", systemImage: "doc.text.magnifyingglass")
            }
            
            Button {
                // Copy tag name
                #if canImport(AppKit)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(tag, forType: .string)
                #endif
            } label: {
                Label("Copy tag name", systemImage: "doc.on.doc")
            }
        }
    }
}

#Preview {
    EnhancedTagsView(appViewModel: AppViewModel())
}