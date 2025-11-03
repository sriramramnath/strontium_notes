//
//  TabBarView.swift
//  Strontium Notes
//
//  Created by Kiro on 02/11/25.
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(appViewModel.openTabs) { tab in
                        TabItem(
                            tab: tab,
                            isActive: appViewModel.activeTabId == tab.id,
                            onSelect: {
                                appViewModel.switchToTab(tab.id)
                            },
                            onClose: {
                                appViewModel.closeTab(tab.id)
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            // New tab button
            Button(action: {
                appViewModel.createNewNote()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.tertiaryText)
                    .frame(width: 28, height: 32)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 32)
        .background(Color.secondaryBackground)
    }
}

struct TabItem: View {
    let tab: NoteTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tab.title)
                .font(.system(size: 11))
                .foregroundColor(isActive ? Color.primaryText : Color.secondaryText)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color.tertiaryText)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isActive ? Color.primaryBackground : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
