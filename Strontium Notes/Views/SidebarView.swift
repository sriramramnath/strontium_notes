//
//  SidebarView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                HStack {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    Text("Strontium Notes")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Vault Info
                if let vault = appViewModel.currentVault {
                    HStack {
                        Label(vault.name, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            
            Divider()
            
            if appViewModel.currentVault != nil {
                // Sidebar Navigation
                VStack(spacing: 0) {
                    ForEach(SidebarItem.allCases, id: \.rawValue) { item in
                        SidebarItemView(
                            item: item,
                            isSelected: appViewModel.selectedSidebarItem == item
                        ) {
                            appViewModel.selectedSidebarItem = item
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Content based on selected sidebar item
                Group {
                    switch appViewModel.selectedSidebarItem {
                    case .files:
                        FilesView(appViewModel: appViewModel)
                    case .search:
                        SearchView(appViewModel: appViewModel)
                    case .tags:
                        TagsView(appViewModel: appViewModel)
                    case .backlinks:
                        BacklinksView(appViewModel: appViewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // No vault open state
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Vault Open")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Button("Open Vault") {
                            appViewModel.openVault()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Create New Vault") {
                            appViewModel.createNewVault()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 280, maxWidth: 350)
    }
}

struct SidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.systemImage)
                    .frame(width: 16)
                Text(item.rawValue)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

#Preview {
    SidebarView(appViewModel: AppViewModel())
        .frame(width: 300, height: 600)
}