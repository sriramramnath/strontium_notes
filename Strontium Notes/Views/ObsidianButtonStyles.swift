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
                Rectangle()
                    .fill(configuration.isPressed ? Color.red.opacity(0.8) : Color.red)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}