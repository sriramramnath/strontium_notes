//
//  CreateVaultView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct CreateVaultView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var vaultName = ""
    @State private var selectedLocation: URL?
    @State private var createSampleNotes = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                
                Text("Create New Vault")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Set up a new vault for your notes")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form
            VStack(alignment: .leading, spacing: 16) {
                // Vault name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vault Name")
                        .font(.headline)
                    
                    TextField("My Notes", text: $vaultName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Location
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location")
                        .font(.headline)
                    
                    HStack {
                        if let location = selectedLocation {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.appendingPathComponent(vaultName).path)
                                    .font(.body)
                                Text("in \(location.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("No location selected")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Choose...") {
                            chooseLocation()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
                
                // Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Options")
                        .font(.headline)
                    
                    Toggle("Create sample notes", isOn: $createSampleNotes)
                        .help("Add some example notes to help you get started")
                }
            }
            
            Spacer()
            
            // Preview
            if !vaultName.isEmpty && selectedLocation != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vault Preview")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(vaultName)
                                .fontWeight(.medium)
                        }
                        
                        if createSampleNotes {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("  ")
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(.secondary)
                                    Text("Welcome.md")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Text("  ")
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(.secondary)
                                    Text("Getting Started.md")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create Vault") {
                    createVault()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vaultName.isEmpty || selectedLocation == nil)
            }
        }
        .padding(24)
        .frame(width: 500, height: 700)
        .onAppear {
            // Set default location to Documents
            selectedLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
    
    private func chooseLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Choose Vault Location"
        panel.message = "Select where to create your new vault"
        
        if panel.runModal() == .OK {
            selectedLocation = panel.url
        }
    }
    
    private func createVault() {
        guard let location = selectedLocation, !vaultName.isEmpty else { return }
        
        let vaultURL = location.appendingPathComponent(vaultName)
        
        // TODO: Implement actual vault creation
        // For now, just create the mock vault
        appViewModel.currentVault = Vault(name: vaultName, rootURL: vaultURL)
        
        if createSampleNotes {
            // Add sample notes to the mock data
            let welcomeNote = Note(
                filePath: "Welcome.md",
                title: "Welcome",
                content: """
                # Welcome to \(vaultName)!
                
                This is your new vault. You can start creating notes and organizing your knowledge here.
                
                ## Getting Started
                - Create new notes using the + button
                - Use [[Note Name]] to link between notes
                - Add #tags to organize your content
                - Use the search function to find information quickly
                
                Happy note-taking! 📝
                """
            )
            
            appViewModel.mockNotes.append(welcomeNote)
        }
        
        dismiss()
    }
}

#Preview {
    CreateVaultView(appViewModel: AppViewModel())
}