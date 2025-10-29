//
//  ObsidianCreateVaultView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianCreateVaultView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var vaultName = ""
    @State private var selectedLocation: URL?
    @State private var createSampleNotes = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create new vault")
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
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Content
            VStack(spacing: 24) {
                // Description
                VStack(spacing: 8) {
                    Text("Create a new vault")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("A vault is a folder where your notes will be stored.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Vault name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vault name")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("My Notes", text: $vaultName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Rectangle()
                                    .fill(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let location = selectedLocation {
                                    Text(location.appendingPathComponent(vaultName).path)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text("in \(location.lastPathComponent)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No location selected")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Browse") {
                                chooseLocation()
                            }
                            .buttonStyle(ObsidianGrayButtonStyle(size: .small))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Options")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        Toggle(isOn: $createSampleNotes) {
                            Text("Create sample notes")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(.checkbox)
                    }
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
            .background(Color.black)
        }
        .frame(width: 450, height: 500)
        .background(Color.black)
        .onAppear {
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
        appViewModel.currentVault = Vault(name: vaultName, rootURL: vaultURL)
        
        if createSampleNotes {
            let welcomeNote = Note(
                filePath: "Welcome.md",
                title: "Welcome",
                content: """
                # Welcome to \(vaultName)!
                
                This is your new vault. Start creating notes and building your knowledge base.
                
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
    ObsidianCreateVaultView(appViewModel: AppViewModel())
}