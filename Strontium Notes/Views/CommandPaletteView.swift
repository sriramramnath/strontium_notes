//
//  CommandPaletteView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedIndex = 0
    
    private var filteredCommands: [Command] {
        let allCommands = Command.allCommands
        if searchText.isEmpty {
            return allCommands
        }
        return allCommands.filter { command in
            command.title.localizedCaseInsensitiveContains(searchText) ||
            command.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "command")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                TextField("Type a command...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // Commands list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        CommandRowView(
                            command: command,
                            isSelected: index == selectedIndex
                        ) {
                            executeCommand(command)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .background(Color.black)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(width: 500)
        .onAppear {
            selectedIndex = 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
    }
    
    private func executeCommand(_ command: Command) {
        isPresented = false
        
        switch command.action {
        case .createNote:
            appViewModel.createNewNote()
        case .search:
            appViewModel.selectedSidebarItem = .search
        case .settings:
            appViewModel.showingPreferences = true
        case .toggleSidebar:
            appViewModel.showRightSidebar.toggle()
        case .switchToEdit:
            appViewModel.editorMode = .edit
        case .switchToPreview:
            appViewModel.editorMode = .preview
        case .switchToWYSIWYM:
            appViewModel.editorMode = .wysiwym
        }
    }
}

struct CommandRowView: View {
    let command: Command
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: command.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(command.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if !command.description.isEmpty {
                        Text(command.description)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let shortcut = command.shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isSelected ? Color.red.opacity(0.8) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct Command {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let shortcut: String?
    let action: CommandAction
    
    static let allCommands: [Command] = [
        Command(title: "Create new note", description: "Create a new markdown note", icon: "plus", shortcut: "⌘N", action: .createNote),
        Command(title: "Search notes", description: "Search through all notes", icon: "magnifyingglass", shortcut: "⌘F", action: .search),
        Command(title: "Switch to WYSIWYM", description: "Switch to What You See Is What You Mean editor", icon: "doc.richtext", shortcut: nil, action: .switchToWYSIWYM),
        Command(title: "Switch to Edit mode", description: "Switch to plain text editor", icon: "pencil", shortcut: nil, action: .switchToEdit),
        Command(title: "Switch to Preview", description: "Switch to preview mode", icon: "eye", shortcut: nil, action: .switchToPreview),
        Command(title: "Toggle sidebar", description: "Show or hide the right sidebar", icon: "sidebar.right", shortcut: nil, action: .toggleSidebar),
        Command(title: "Settings", description: "Open application settings", icon: "gear", shortcut: "⌘,", action: .settings),
    ]
}

enum CommandAction {
    case createNote
    case search
    case settings
    case toggleSidebar
    case switchToEdit
    case switchToPreview
    case switchToWYSIWYM
}