//
//  ColorScheme.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

extension Color {
    // Obsidian-inspired color scheme matching the exact dark theme
    
    // Background colors - Exact Obsidian dark theme
    static let primaryBackground = Color("PrimaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.98, green: 0.98, blue: 0.98), dark: Color(red: 0.118, green: 0.118, blue: 0.118)) // #1e1e1e
    
    static let secondaryBackground = Color("SecondaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.95, green: 0.95, blue: 0.95), dark: Color(red: 0.157, green: 0.157, blue: 0.157)) // #282828
    
    static let tertiaryBackground = Color("TertiaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.92, green: 0.92, blue: 0.92), dark: Color(red: 0.196, green: 0.196, blue: 0.196)) // #323232
    
    // Text colors - Exact Obsidian text colors
    static let primaryText = Color("PrimaryText", bundle: nil)
        .fallback(light: Color(red: 0.1, green: 0.1, blue: 0.1), dark: Color(red: 0.863, green: 0.863, blue: 0.863)) // #dcdcdc
    
    static let secondaryText = Color("SecondaryText", bundle: nil)
        .fallback(light: Color(red: 0.4, green: 0.4, blue: 0.4), dark: Color(red: 0.667, green: 0.667, blue: 0.667)) // #aaaaaa
    
    static let tertiaryText = Color("TertiaryText", bundle: nil)
        .fallback(light: Color(red: 0.6, green: 0.6, blue: 0.6), dark: Color(red: 0.502, green: 0.502, blue: 0.502)) // #808080
    
    // Accent colors - Obsidian purple accent
    static let accent = Color(red: 0.588, green: 0.353, blue: 0.902) // #9656e6 - Obsidian purple
    static let accentHover = Color(red: 0.647, green: 0.451, blue: 0.922) // Lighter purple for hover
    static let destructive = Color(red: 0.902, green: 0.298, blue: 0.235) // #e64c3c
    static let success = Color(red: 0.18, green: 0.8, blue: 0.443) // #2ecc71
    
    // Border colors - Exact Obsidian borders
    static let primaryBorder = Color("PrimaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.85, green: 0.85, blue: 0.85), dark: Color(red: 0.235, green: 0.235, blue: 0.235)) // #3c3c3c
    
    static let secondaryBorder = Color("SecondaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.9, green: 0.9, blue: 0.9), dark: Color(red: 0.196, green: 0.196, blue: 0.196)) // #323232
    
    // Helper for fallback colors
    func fallback(light: Color, dark: Color) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        } ?? NSColor(light))
        #else
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }
}

// Theme preference storage
class ThemeManager: ObservableObject {
    @Published var preferredColorScheme: ColorScheme? = nil
    
    private let themeKey = "com.strontium.preferredTheme"
    
    init() {
        loadTheme()
    }
    
    func setTheme(_ theme: ColorScheme?) {
        preferredColorScheme = theme
        saveTheme()
    }
    
    private func loadTheme() {
        if let themeValue = UserDefaults.standard.string(forKey: themeKey) {
            switch themeValue {
            case "light":
                preferredColorScheme = .light
            case "dark":
                preferredColorScheme = .dark
            default:
                preferredColorScheme = nil
            }
        }
    }
    
    private func saveTheme() {
        if let theme = preferredColorScheme {
            let themeValue = theme == .light ? "light" : "dark"
            UserDefaults.standard.set(themeValue, forKey: themeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: themeKey)
        }
    }
}