//
//  KeyboardShortcuts.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

/// Keyboard shortcut definitions
enum KeyboardShortcut: String, CaseIterable {
    case newNote = "n"
    case search = "f"
    case commandPalette = "p"
    case toggleSidebar = "b"
    case splitHorizontal = "h"
    case splitVertical = "v"
    case closePane = "w"
    case save = "s"
    case delete = "backspace"
    case rename = "r"
    
    var modifiers: EventModifiers {
        switch self {
        case .newNote, .search, .save:
            return .command
        case .commandPalette, .splitHorizontal, .splitVertical:
            return [.command, .shift]
        case .toggleSidebar, .rename:
            return [.command, .option]
        case .closePane:
            return [.command]
        case .delete:
            return [.command]
        }
    }
    
    var description: String {
        switch self {
        case .newNote:
            return "New Note"
        case .search:
            return "Search"
        case .commandPalette:
            return "Command Palette"
        case .toggleSidebar:
            return "Toggle Sidebar"
        case .splitHorizontal:
            return "Split Horizontally"
        case .splitVertical:
            return "Split Vertically"
        case .closePane:
            return "Close Pane"
        case .save:
            return "Save"
        case .delete:
            return "Delete"
        case .rename:
            return "Rename"
        }
    }
    
    var displayString: String {
        let modifierString = modifiers.contains(.command) ? "⌘" : ""
        let shiftString = modifiers.contains(.shift) ? "⇧" : ""
        let optionString = modifiers.contains(.option) ? "⌥" : ""
        let key = rawValue.uppercased()
        return "\(modifierString)\(shiftString)\(optionString)\(key)"
    }
}

/// View modifier for keyboard shortcuts
struct KeyboardShortcutModifier: ViewModifier {
    let shortcut: KeyboardShortcut
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .keyboardShortcut(KeyEquivalent(Character(shortcut.rawValue)), modifiers: shortcut.modifiers)
    }
}

extension View {
    func keyboardShortcut(_ shortcut: KeyboardShortcut, action: @escaping () -> Void) -> some View {
        self.modifier(KeyboardShortcutModifier(shortcut: shortcut, action: action))
    }
}
