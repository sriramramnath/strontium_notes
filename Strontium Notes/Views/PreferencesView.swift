//
//  PreferencesView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: PreferencesTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Preferences")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(PreferencesTab.allCases, id: \.self) { tab in
                        PreferencesTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 150)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Content area
                Group {
                    switch selectedTab {
                    case .general:
                        GeneralPreferencesView()
                    case .editor:
                        EditorPreferencesView()
                    case .appearance:
                        AppearancePreferencesView()
                    case .shortcuts:
                        ShortcutsPreferencesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
}

enum PreferencesTab: String, CaseIterable {
    case general = "General"
    case editor = "Editor"
    case appearance = "Appearance"
    case shortcuts = "Shortcuts"
    
    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .editor: return "square.and.pencil"
        case .appearance: return "paintbrush"
        case .shortcuts: return "keyboard"
        }
    }
}

struct PreferencesTabButton: View {
    let tab: PreferencesTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .frame(width: 16)
                Text(tab.rawValue)
                Spacer()
            }
            .padding(.horizontal, 12)
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

struct GeneralPreferencesView: View {
    @State private var autoSave = true
    @State private var autoSaveInterval = 30.0
    @State private var enableFileWatcher = true
    @State private var maxSearchResults = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Auto-save notes", isOn: $autoSave)
                    .help("Automatically save notes as you type")
                
                if autoSave {
                    HStack {
                        Text("Auto-save interval:")
                        Slider(value: $autoSaveInterval, in: 5...120, step: 5) {
                            Text("Interval")
                        }
                        Text("\(Int(autoSaveInterval))s")
                            .frame(width: 30)
                    }
                }
                
                Toggle("Watch for file changes", isOn: $enableFileWatcher)
                    .help("Automatically update notes when files change on disk")
                
                HStack {
                    Text("Maximum search results:")
                    TextField("100", value: $maxSearchResults, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EditorPreferencesView: View {
    @State private var enableLaTeX = true
    @State private var showLineNumbers = false
    @State private var wrapText = true
    @State private var fontSize = 14.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Editor")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable LaTeX rendering", isOn: $enableLaTeX)
                    .help("Render mathematical expressions in notes")
                
                Toggle("Show line numbers", isOn: $showLineNumbers)
                
                Toggle("Wrap text", isOn: $wrapText)
                
                HStack {
                    Text("Font size:")
                    Slider(value: $fontSize, in: 10...24, step: 1) {
                        Text("Font Size")
                    }
                    Text("\(Int(fontSize))pt")
                        .frame(width: 40)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppearancePreferencesView: View {
    @State private var selectedTheme = "System"
    @State private var accentColor = Color.blue
    
    private let themes = ["System", "Light", "Dark"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Theme:")
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                HStack {
                    Text("Accent color:")
                    ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)
                        .labelsHidden()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShortcutsPreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                ShortcutRowView(action: "New Note", shortcut: "⌘N")
                ShortcutRowView(action: "Open Vault", shortcut: "⌘O")
                ShortcutRowView(action: "Search", shortcut: "⌘F")
                ShortcutRowView(action: "Quick Open", shortcut: "⌘P")
                ShortcutRowView(action: "Toggle Sidebar", shortcut: "⌘\\")
                ShortcutRowView(action: "Focus Editor", shortcut: "⌘E")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShortcutRowView: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
        }
    }
}

#Preview {
    PreferencesView()
}