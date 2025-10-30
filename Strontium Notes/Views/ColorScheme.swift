//
//  ColorScheme.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

extension Color {
    // Adaptive color scheme that supports both light and dark modes
    
    // Background colors
    static let primaryBackground = Color("PrimaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.98, green: 0.98, blue: 0.98), dark: Color(red: 0.11, green: 0.11, blue: 0.12))
    
    static let secondaryBackground = Color("SecondaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.95, green: 0.95, blue: 0.95), dark: Color(red: 0.14, green: 0.14, blue: 0.15))
    
    static let tertiaryBackground = Color("TertiaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.92, green: 0.92, blue: 0.92), dark: Color(red: 0.17, green: 0.17, blue: 0.18))
    
    // Text colors
    static let primaryText = Color("PrimaryText", bundle: nil)
        .fallback(light: Color(red: 0.1, green: 0.1, blue: 0.1), dark: Color(red: 0.95, green: 0.95, blue: 0.95))
    
    static let secondaryText = Color("SecondaryText", bundle: nil)
        .fallback(light: Color(red: 0.4, green: 0.4, blue: 0.4), dark: Color(red: 0.7, green: 0.7, blue: 0.7))
    
    static let tertiaryText = Color("TertiaryText", bundle: nil)
        .fallback(light: Color(red: 0.6, green: 0.6, blue: 0.6), dark: Color(red: 0.5, green: 0.5, blue: 0.5))
    
    // Accent colors (same in both modes)
    static let accent = Color(red: 0.95, green: 0.26, blue: 0.21) // Red accent
    static let destructive = Color(red: 0.8, green: 0.1, blue: 0.1) // Darker red for destructive
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    // Border colors
    static let primaryBorder = Color("PrimaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.85, green: 0.85, blue: 0.85), dark: Color(red: 0.25, green: 0.25, blue: 0.26))
    
    static let secondaryBorder = Color("SecondaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.9, green: 0.9, blue: 0.9), dark: Color(red: 0.2, green: 0.2, blue: 0.21))
    
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