//
//  Strontium_NotesApp.swift
//  Strontium Notes
//
//  Created by Sriram Ramnath on 29/10/25.
//

import SwiftUI

@main
struct Strontium_NotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    // This will be handled by the ContentView
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
        }
    }
}

extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let focusSearch = Notification.Name("focusSearch")
    static let showCommandPalette = Notification.Name("showCommandPalette")
}
