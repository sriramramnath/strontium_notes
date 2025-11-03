//
//  ObsidianPreferencesView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianPreferencesView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ObsidianPreferencesTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
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
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(ObsidianPreferencesTab.allCases, id: \.self) { tab in
                        ObsidianPreferencesTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 150)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1)
                
                // Content area
                Group {
                    switch selectedTab {
                    case .general:
                        ObsidianGeneralPreferencesView()
                    case .editor:
                        ObsidianEditorPreferencesView()
                    case .ai:
                        ObsidianAIPreferencesView(appViewModel: appViewModel)
                    case .appearance:
                        ObsidianAppearancePreferencesView()
                    case .about:
                        ObsidianAboutPreferencesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.black)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color.black)
    }
}

enum ObsidianPreferencesTab: String, CaseIterable {
    case general = "General"
    case editor = "Editor"
    case ai = "AI Assistant"
    case appearance = "Appearance"
    case about = "About"
    
    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .editor: return "square.and.pencil"
        case .ai: return "sparkles"
        case .appearance: return "paintbrush"
        case .about: return "info.circle"
        }
    }
}

struct ObsidianPreferencesTabButton: View {
    let tab: ObsidianPreferencesTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 16)
                
                Text(tab.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.gray.opacity(0.2) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

struct ObsidianGeneralPreferencesView: View {
    @State private var autoSave = true
    @State private var autoSaveInterval = 30.0
    @State private var enableFileWatcher = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("General")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $autoSave) {
                    Text("Auto-save notes")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .toggleStyle(.checkbox)
                
                if autoSave {
                    HStack(spacing: 12) {
                        Text("Auto-save interval:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Slider(value: $autoSaveInterval, in: 5...120, step: 5)
                            .frame(width: 120)
                        
                        Text("\(Int(autoSaveInterval))s")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 30)
                    }
                    .padding(.leading, 20)
                }
                
                Toggle(isOn: $enableFileWatcher) {
                    Text("Watch for file changes")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .toggleStyle(.checkbox)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ObsidianEditorPreferencesView: View {
    @State private var enableLaTeX = true
    @State private var showLineNumbers = false
    @State private var fontSize = 14.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Editor")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $enableLaTeX) {
                    Text("Enable LaTeX rendering")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $showLineNumbers) {
                    Text("Show line numbers")
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                }
                .toggleStyle(.checkbox)
                
                HStack(spacing: 12) {
                    Text("Font size:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Slider(value: $fontSize, in: 10...24, step: 1)
                        .frame(width: 120)
                    
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 30)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ObsidianAppearancePreferencesView: View {
    @State private var selectedTheme = "Light"
    
    private let themes = ["Light", "Dark"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Appearance")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Text("Theme:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                
                Text("Note: Strontium Notes uses a minimalist black and white design with red accents.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ObsidianAboutPreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("About")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strontium Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Developer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Sriram Ramnath")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    
                    Text("sriramramnath2011@gmail.com")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    
                    Text("@sriramramnath")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
                
                Text("A minimalist knowledge management app built with SwiftUI.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ObsidianPreferencesView(appViewModel: AppViewModel())
}

// MARK: - AI Preferences
struct ObsidianAIPreferencesView: View {
    @ObservedObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Assistant")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Configure your AI provider and API keys")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Provider Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Provider")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        AIProviderOption(
                            provider: provider,
                            isSelected: appViewModel.aiProvider == provider
                        ) {
                            appViewModel.aiProvider = provider
                        }
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // API Keys
                VStack(alignment: .leading, spacing: 16) {
                    Text("API Keys")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Gemini API Key
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.accent)
                            Text("Google Gemini API Key")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                        
                        TextField("Enter your Gemini API key", text: $appViewModel.geminiAPIKey)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        
                        Link("Get API Key →", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                            .font(.system(size: 12))
                            .foregroundColor(Color.accent)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("About API Keys")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Your API keys are stored locally and never shared. They are used only to communicate with your chosen AI provider.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(24)
        }
        .background(Color.black)
    }
}

struct AIProviderOption: View {
    let provider: AIProvider
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: provider.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Color.accent : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("Google's latest AI model")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.accent)
                }
            }
            .padding(12)
            .background(isSelected ? Color.accent.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
