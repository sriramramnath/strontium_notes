//
//  Strontium_NotesApp.swift
//  Strontium Notes
//
//  Created by Sriram Ramnath on 29/10/25.
//

import SwiftUI

@main
struct Strontium_NotesApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Search") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Command Palette") {
                    NotificationCenter.default.post(name: .showCommandPalette, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
            
            CommandMenu("View") {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                
                Divider()
                
                Button("Split Horizontally") {
                    NotificationCenter.default.post(name: .splitHorizontal, object: nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                
                Button("Split Vertically") {
                    NotificationCenter.default.post(name: .splitVertical, object: nil)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Light Mode") {
                    NotificationCenter.default.post(name: .setLightMode, object: nil)
                }
                
                Button("Dark Mode") {
                    NotificationCenter.default.post(name: .setDarkMode, object: nil)
                }
                
                Button("System Theme") {
                    NotificationCenter.default.post(name: .setSystemTheme, object: nil)
                }
            }
        }
    }
}

extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let focusSearch = Notification.Name("focusSearch")
    static let showCommandPalette = Notification.Name("showCommandPalette")
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let setLightMode = Notification.Name("setLightMode")
    static let setDarkMode = Notification.Name("setDarkMode")
    static let setSystemTheme = Notification.Name("setSystemTheme")
    static let splitHorizontal = Notification.Name("splitHorizontal")
    static let splitVertical = Notification.Name("splitVertical")
}
