//
//  ColorScheme.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI
import Combine

extension Color {
    // VS Code Dark+ theme colors - exact match
    
    // Background colors - Obsidian exact colors (darker)
    static let primaryBackground = Color("PrimaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.98, green: 0.98, blue: 0.98), dark: Color(red: 0.098, green: 0.098, blue: 0.098)) // #191919 - darker editor background
    
    static let secondaryBackground = Color("SecondaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.95, green: 0.95, blue: 0.95), dark: Color(red: 0.118, green: 0.118, blue: 0.118)) // #1e1e1e - darker sidebar background
    
    static let tertiaryBackground = Color("TertiaryBackground", bundle: nil)
        .fallback(light: Color(red: 0.92, green: 0.92, blue: 0.92), dark: Color(red: 0.145, green: 0.145, blue: 0.145)) // #252525 - hover background
    
    // Text colors - Obsidian text colors
    static let primaryText = Color("PrimaryText", bundle: nil)
        .fallback(light: Color(red: 0.1, green: 0.1, blue: 0.1), dark: Color(red: 1.0, green: 1.0, blue: 1.0)) // #ffffff - main text (white)
    
    static let secondaryText = Color("SecondaryText", bundle: nil)
        .fallback(light: Color(red: 0.4, green: 0.4, blue: 0.4), dark: Color(red: 0.831, green: 0.831, blue: 0.831)) // #d4d4d4 - secondary text
    
    static let tertiaryText = Color("TertiaryText", bundle: nil)
        .fallback(light: Color(red: 0.6, green: 0.6, blue: 0.6), dark: Color(red: 0.541, green: 0.541, blue: 0.541)) // #8a8a8a - tertiary text
    
    // Accent colors - Modern red gradient
    static let accent = Color(red: 0.957, green: 0.263, blue: 0.212) // #F44336 - Modern red
    static let accentHover = Color(red: 1.0, green: 0.341, blue: 0.275) // #FF5746 - Lighter red for hover
    static let accentSecondary = Color(red: 0.835, green: 0.157, blue: 0.157) // #D52828 - Darker red variant
    static let destructive = Color(red: 0.957, green: 0.263, blue: 0.212) // #f44336 - Red
    static let success = Color(red: 0.298, green: 0.686, blue: 0.314) // #4caf50 - Green
    static let warning = Color(red: 1.0, green: 0.757, blue: 0.027) // #FFC107 - Amber
    
    // Border colors - Obsidian borders
    static let primaryBorder = Color("PrimaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.85, green: 0.85, blue: 0.85), dark: Color(red: 0.227, green: 0.227, blue: 0.227)) // #3a3a3a - borders
    
    static let secondaryBorder = Color("SecondaryBorder", bundle: nil)
        .fallback(light: Color(red: 0.9, green: 0.9, blue: 0.9), dark: Color(red: 0.176, green: 0.176, blue: 0.176)) // #2d2d2d
    
    // Helper for fallback colors
    func fallback(light: Color, dark: Color) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
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