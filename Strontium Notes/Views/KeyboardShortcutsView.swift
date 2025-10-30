//
//  KeyboardShortcutsView.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import SwiftUI

struct KeyboardShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(KeyboardShortcut.allCases, id: \.rawValue) { shortcut in
                        HStack {
                            Text(shortcut.description)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text(shortcut.displayString)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.tertiaryBackground)
                                .cornerRadius(6)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.vertical, 4)
                        
                        if shortcut != KeyboardShortcut.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

#Preview {
    KeyboardShortcutsView()
}
