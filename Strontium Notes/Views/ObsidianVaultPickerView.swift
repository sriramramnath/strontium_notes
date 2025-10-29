//
//  ObsidianVaultPickerView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianVaultPickerView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Open vault")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.black)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // Content
            VStack(spacing: 24) {
                // Description
                VStack(spacing: 8) {
                    Text("Choose an existing vault")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("A vault is a folder on your computer where your notes are stored.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Recent vaults
                if !appViewModel.recentVaults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent vaults")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 4) {
                            ForEach(appViewModel.recentVaults) { vaultRef in
                                ObsidianRecentVaultRowView(vaultReference: vaultRef) {
                                    // TODO: Open recent vault
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                
                // Browse section
                VStack(spacing: 16) {
                    Button("Browse") {
                        openFolderPicker()
                    }
                    .buttonStyle(ObsidianRedButtonStyle(size: .large))
                    
                    if let selectedURL = selectedURL {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text(selectedURL.lastPathComponent)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text(selectedURL.path)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Rectangle()
                                .fill(Color.green.opacity(0.05))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(ObsidianGrayButtonStyle())
                    
                    Button("Open") {
                        if let url = selectedURL {
                            openVault(at: url)
                        }
                    }
                    .buttonStyle(ObsidianRedButtonStyle())
                    .disabled(selectedURL == nil)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .frame(width: 450, height: 500)
        .background(Color.black)
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
        appViewModel.currentVault = Vault(name: url.lastPathComponent, rootURL: url)
        dismiss()
    }
}

struct ObsidianRecentVaultRowView: View {
    let vaultReference: VaultReference
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vaultReference.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(vaultReference.path)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Text(vaultReference.lastAccessedDate, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ObsidianVaultPickerView(appViewModel: AppViewModel())
}