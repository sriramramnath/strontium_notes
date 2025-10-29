//
//  VaultPickerView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct VaultPickerView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("Open Vault")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Select a folder to use as your vault")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Recent vaults
            if !appViewModel.recentVaults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Vaults")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(appViewModel.recentVaults) { vaultRef in
                        RecentVaultRowView(vaultReference: vaultRef) {
                            // TODO: Open recent vault
                            dismiss()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            
            // Browse button
            VStack(spacing: 12) {
                Button("Browse for Folder...") {
                    openFolderPicker()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if let selectedURL = selectedURL {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(selectedURL.lastPathComponent)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        HStack {
                            Text(selectedURL.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                            .stroke(Color.green, lineWidth: 1)
                    )
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Open Vault") {
                    if let url = selectedURL {
                        openVault(at: url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURL == nil)
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
    
    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Vault Folder"
        panel.message = "Choose a folder to use as your vault"
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }
    
    private func openVault(at url: URL) {
        // TODO: Implement actual vault opening
        // For now, just update the mock data
        appViewModel.currentVault = Vault(name: url.lastPathComponent, rootURL: url)
        dismiss()
    }
}

struct RecentVaultRowView: View {
    let vaultReference: VaultReference
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vaultReference.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(vaultReference.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Text(vaultReference.lastAccessedDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VaultPickerView(appViewModel: AppViewModel())
}