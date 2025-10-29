//
//  SimpleTextEditor.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI
import AppKit

struct SimpleTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onTextChange: (String) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Dark mode styling
        textView.backgroundColor = NSColor.black
        textView.textColor = NSColor.white
        textView.insertionPointColor = NSColor.white
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.systemBlue.withAlphaComponent(0.3),
            .foregroundColor: NSColor.white
        ]
        
        // Font and spacing
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 20, height: 16)
        
        // Set initial text
        textView.string = text
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.black
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SimpleTextEditor
        
        init(_ parent: SimpleTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            parent.text = textView.string
            parent.isEditing = true
            parent.onTextChange(textView.string)
        }
    }
}