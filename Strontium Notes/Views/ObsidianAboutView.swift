//
//  ObsidianAboutView.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct ObsidianAboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("About Strontium Notes")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.black)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // Content
            VStack(spacing: 32) {
                // App icon and info
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    
                    VStack(spacing: 8) {
                        Text("Strontium Notes")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text("A minimalist knowledge management app")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Developer info
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Made by")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Sriram Ramnath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Contact links
                    VStack(spacing: 12) {
                        // Email
                        Button {
                            if let url = URL(string: "mailto:sriramramnath2011@gmail.com") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                Text("sriramramnath2011@gmail.com")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        
                        // GitHub
                        Button {
                            if let url = URL(string: "https://github.com/sriramramnath") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                Text("@sriramramnath")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Footer
                VStack(spacing: 8) {
                    Text("Built with SwiftUI")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Text("© 2024 Sriram Ramnath. All rights reserved.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .frame(width: 400, height: 500)
        .background(Color.black)
    }
}

#Preview {
    ObsidianAboutView()
}