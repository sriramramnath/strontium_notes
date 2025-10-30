//
//  ObsidianWelcomeView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianWelcomeView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Logo/Icon
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(Color.accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.accent)
                }
                
                VStack(spacing: 4) {
                    Text("Strontium Notes")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(.primaryText)
                    
                    Text("Knowledge Management")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accent.opacity(0.8))
                        .tracking(2)
                }
            }
            
            // Welcome message
            VStack(spacing: 12) {
                Text("Welcome to your digital workspace")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Text("Create, organize, and connect your thoughts with powerful markdown editing")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 400)
            }
            
            // Quick actions
            if appViewModel.currentVault != nil {
                VStack(spacing: 12) {
                    Button("Create new note") {
                        appViewModel.createNewNote()
                    }
                    .buttonStyle(ObsidianRedButtonStyle(size: .large))
                    
                    HStack(spacing: 16) {
                        Button("Search notes") {
                            appViewModel.selectedSidebarItem = .search
                        }
                        .buttonStyle(ObsidianGrayButtonStyle())
                        
                        Button("Settings") {
                            appViewModel.presentedSheet = .preferences
                        }
                        .buttonStyle(ObsidianGrayButtonStyle())
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Button("Open vault") {
                        appViewModel.openVault()
                    }
                    .buttonStyle(ObsidianRedButtonStyle(size: .large))
                    
                    Button("Create new vault") {
                        appViewModel.createNewVault()
                    }
                    .buttonStyle(ObsidianGrayButtonStyle())
                }
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("Strontium Notes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.tertiaryText)
                
                Text("A minimalist knowledge management app")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

#Preview {
    ObsidianWelcomeView(appViewModel: AppViewModel())
        .frame(width: 600, height: 500)
}