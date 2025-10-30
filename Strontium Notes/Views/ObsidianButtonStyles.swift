//
//  ObsidianButtonStyles.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianRedButtonStyle: ButtonStyle {
    enum Size {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 12
            case .large: return 13
            }
        }
    }
    
    let size: Size
    
    init(size: Size = .medium) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.accent.opacity(0.8) : Color.accent)
                    .shadow(
                        color: Color.accent.opacity(0.3),
                        radius: configuration.isPressed ? 2 : 4,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ObsidianGrayButtonStyle: ButtonStyle {
    enum Size {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 12
            case .large: return 13
            }
        }
    }
    
    let size: Size
    
    init(size: Size = .medium) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(.primaryText)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.tertiaryBackground : Color.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primaryBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: configuration.isPressed ? 1 : 3,
                        x: 0,
                        y: configuration.isPressed ? 0 : 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}