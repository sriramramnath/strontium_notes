//
//  ObsidianConstants.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

/// Exact Obsidian UI constants for pixel-perfect matching
enum ObsidianUI {
    // Spacing
    static let tinySpacing: CGFloat = 4
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 12
    static let largeSpacing: CGFloat = 16
    static let xlargeSpacing: CGFloat = 24
    
    // Corner radius
    static let smallRadius: CGFloat = 4
    static let mediumRadius: CGFloat = 6
    static let largeRadius: CGFloat = 8
    
    // Sidebar - more compact like Obsidian
    static let sidebarWidth: CGFloat = 240
    static let sidebarHeaderHeight: CGFloat = 36
    static let sidebarItemHeight: CGFloat = 24
    static let sidebarIconSize: CGFloat = 14
    static let sidebarIndent: CGFloat = 16
    
    // Font sizes - smaller like Obsidian
    static let tinyFont: CGFloat = 9
    static let smallFont: CGFloat = 11
    static let bodyFont: CGFloat = 12
    static let mediumFont: CGFloat = 13
    static let largeFont: CGFloat = 14
    static let titleFont: CGFloat = 16
    
    // Icon sizes
    static let tinyIcon: CGFloat = 12
    static let smallIcon: CGFloat = 14
    static let mediumIcon: CGFloat = 16
    static let largeIcon: CGFloat = 20
    
    // Border widths
    static let thinBorder: CGFloat = 1
    static let mediumBorder: CGFloat = 2
    
    // Opacity values
    static let hoverOpacity: Double = 0.08
    static let activeOpacity: Double = 0.15
    static let disabledOpacity: Double = 0.5
    
    // Animation durations
    static let fastAnimation: Double = 0.15
    static let normalAnimation: Double = 0.25
    static let slowAnimation: Double = 0.35
}
