//
//  ObsidianAboutView.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

struct ObsidianAboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("About")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.secondaryBackground)
            
            Rectangle()
                .fill(Color.primaryBorder)
                .frame(height: 1)
            
            // Content
            VStack(spacing: 32) {
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .stroke(Color.accent.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.accent)
                }
                .padding(.top, 32)
                
                // App info
                VStack(spacing: 8) {
                    Text("Strontium Notes")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundColor(.primaryText)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                    
                    Text("Knowledge Management")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accent.opacity(0.8))
                        .tracking(2)
                }
                
                // Description
                Text("A minimalist knowledge management app\nbuilt with SwiftUI")
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Developer info
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 6) {
                        Text("Developer")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.tertiaryText)
                        
                        Text("Sriram Ramnath")
                            .font(.system(size: 13))
                            .foregroundColor(.primaryText)
                        
                        Text("@sriramramnath")
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                // Footer
                Text("© 2025 Strontium Notes. All rights reserved.")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryText)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
        }
        .frame(width: 400, height: 550)
        .background(Color.primaryBackground)
    }
}

#Preview {
    ObsidianAboutView()
}
