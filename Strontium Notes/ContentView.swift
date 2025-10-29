//
//  ContentView.swift
//  Strontium Notes
//
//  Created by Sriram Ramnath on 29/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar - File Explorer
            ObsidianSidebarView(appViewModel: appViewModel)
                .frame(width: 280)
            
            // Vertical Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // Main Content Area
            if appViewModel.selectedNote != nil {
                ObsidianEditorView(appViewModel: appViewModel)
            } else {
                ObsidianWelcomeView(appViewModel: appViewModel)
            }
            
            // Right Sidebar - Backlinks/Outline (collapsible)
            if appViewModel.showRightSidebar {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                
                ObsidianRightSidebarView(appViewModel: appViewModel)
                    .frame(width: 280)
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            appViewModel.createNewNote()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            appViewModel.selectedSidebarItem = .search
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCommandPalette)) { _ in
            appViewModel.showCommandPalette = true
        }
        .sheet(isPresented: $appViewModel.isVaultPickerPresented) {
            ObsidianVaultPickerView(appViewModel: appViewModel)
        }
        .sheet(isPresented: $appViewModel.isCreateVaultPresented) {
            ObsidianCreateVaultView(appViewModel: appViewModel)
        }
        .sheet(isPresented: $appViewModel.showingPreferences) {
            ObsidianPreferencesView(appViewModel: appViewModel)
        }
        .sheet(isPresented: $appViewModel.showingAbout) {
            ObsidianAboutView()
        }
        .overlay(
            Group {
                if appViewModel.showCommandPalette {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            appViewModel.showCommandPalette = false
                        }
                    
                    CommandPaletteView(appViewModel: appViewModel, isPresented: $appViewModel.showCommandPalette)
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
