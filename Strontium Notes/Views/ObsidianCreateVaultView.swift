//
//  ObsidianCreateVaultView.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

struct ObsidianCreateVaultView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var vaultName = ""
    @State private var selectedLocation: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create new vault")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.secondaryBackground)
            
            Rectangle()
                .fill(Color.primaryBorder)
                .frame(height: 1)
            
            // Content
            VStack(spacing: 24) {
                // Description
                VStack(spacing: 8) {
                    Text("Create a new vault")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryText)
                    
                    Text("A vault is a folder where your notes will be stored.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                // Vault name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vault name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    TextField("My Vault", text: $vaultName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.tertiaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.primaryBorder, lineWidth: 1)
                                )
                        )
                }
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: 12) {
                        if let location = selectedLocation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.lastPathComponent)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primaryText)
                                
                                Text(location.path)
                                    .font(.system(size: 11))
                                    .foregroundColor(.tertiaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("No location selected")
                                .font(.system(size: 13))
                                .foregroundColor(.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button("Browse") {
                            selectLocation()
                        }
                        .buttonStyle(ObsidianGrayButtonStyle(size: .small))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.tertiaryBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primaryBorder, lineWidth: 1)
                            )
                    )
                }
                
                // Error message
                if showError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.destructive)
                        
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.destructive)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.destructive.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(ObsidianGrayButtonStyle())
                    
                    Button("Create") {
                        createVault()
                    }
                    .buttonStyle(ObsidianRedButtonStyle())
                    .disabled(vaultName.isEmpty || selectedLocation == nil)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
        }
        .frame(width: 450, height: 450)
        .background(Color.primaryBackground)
    }
    
    private func selectLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Location"
        panel.message = "Choose where to create your vault"
        
        if panel.runModal() == .OK {
            selectedLocation = panel.url
        }
    }
    
    private func createVault() {
        guard let location = selectedLocation else {
            showError = true
            errorMessage = "Please select a location"
            return
        }
        
        guard !vaultName.isEmpty else {
            showError = true
            errorMessage = "Please enter a vault name"
            return
        }
        
        Task {
            do {
                _ = try await appViewModel.vaultManager.createVault(name: vaultName, at: location)
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ObsidianCreateVaultView(appViewModel: AppViewModel())
}
