//
//  WYSIWYMEditor.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI
import AppKit

struct WYSIWYMEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onTextChange: (String) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = MarkdownTextView(frame: .zero, textContainer: nil)
        
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Dark mode styling - ensure visibility
        textView.backgroundColor = NSColor.black
        textView.textColor = NSColor.white
        textView.insertionPointColor = NSColor.white
        textView.selectedTextAttributes = [
            NSAttributedString.Key.backgroundColor: NSColor.systemBlue.withAlphaComponent(0.3),
            NSAttributedString.Key.foregroundColor: NSColor.white
        ]
        
        // Font and spacing
        textView.font = NSFont.systemFont(ofSize: 14)
        
        // Set initial text if available
        textView.string = text
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor.black
        
        // Ensure the scroll view is properly configured
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? MarkdownTextView else { return }
        
        if textView.string != text {
            textView.string = text
            // Force initial rendering if text is empty
            if text.isEmpty {
                textView.textColor = NSColor.white
                textView.backgroundColor = NSColor.black
            }
            textView.renderMarkdown()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: WYSIWYMEditor
        
        init(_ parent: WYSIWYMEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? MarkdownTextView else { return }
            
            parent.text = textView.string
            parent.isEditing = true
            parent.onTextChange(textView.string)
            
            // Re-render markdown with a slight delay to avoid performance issues
            // Only re-render if the text has actually changed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                textView.renderMarkdownIfNeeded()
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let replacementString = replacementString else {
                return true
            }
            
            // Handle markdown auto-completion
            if replacementString == "*" {
                let text = textView.string
                let location = affectedCharRange.location
                
                // Check if we're typing the second * for bold
                if location > 0 && text[text.index(text.startIndex, offsetBy: location - 1)] == "*" {
                    // Auto-complete bold syntax
                    textView.insertText("**", replacementRange: affectedCharRange)
                    textView.setSelectedRange(NSRange(location: location + 1, length: 0))
                    return false
                }
            }
            
            // Handle bracket auto-completion for wikilinks
            if replacementString == "[" {
                let text = textView.string
                let location = affectedCharRange.location
                
                // Check if we're typing the second [ for wikilink
                if location > 0 && text[text.index(text.startIndex, offsetBy: location - 1)] == "[" {
                    // Auto-complete wikilink syntax
                    textView.insertText("[]", replacementRange: affectedCharRange)
                    textView.setSelectedRange(NSRange(location: location + 1, length: 0))
                    return false
                }
            }
            
            return true
        }
    }
}

class MarkdownTextView: NSTextView {
    private var isRendering = false
    private var lastRenderedText = ""
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextView()
    }
    
    private func setupTextView() {
        textContainerInset = NSSize(width: 20, height: 16)
        backgroundColor = NSColor.black
        textColor = NSColor.white
        insertionPointColor = NSColor.white
        font = NSFont.systemFont(ofSize: 13)
        
        // Enable better text rendering
        layoutManager?.allowsNonContiguousLayout = false
        
        // Ensure text is visible
        drawsBackground = true
        isRichText = false  // Start with plain text to ensure visibility
        allowsUndo = true
        isEditable = true
        isSelectable = true
        
        // Force white text color
        textColor = NSColor.white
        
        // Better line spacing (more compact like Obsidian)
        defaultParagraphStyle = createParagraphStyle()
        typingAttributes = [
            NSAttributedString.Key.foregroundColor: NSColor.white,
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 13),
            NSAttributedString.Key.paragraphStyle: createParagraphStyle()
        ]
        
        // Ensure the text view updates properly
        needsDisplay = true
    }
    
    func renderMarkdownIfNeeded() {
        guard string != lastRenderedText else { return }
        renderMarkdown()
    }
    
    func renderMarkdown() {
        guard !isRendering else { return }
        isRendering = true
        
        let currentText = string
        _ = selectedRange()
        lastRenderedText = currentText
        
        // Always ensure white text on black background
        textColor = NSColor.white
        backgroundColor = NSColor.black
        
        // If text is empty, just ensure basic styling
        if currentText.isEmpty {
            font = NSFont.systemFont(ofSize: 14)
            isRendering = false
            return
        }
        
        // For now, keep it simple - just ensure text is visible
        // We can add markdown styling later once text visibility is confirmed
        font = NSFont.systemFont(ofSize: 14)
        textColor = NSColor.white
        
        isRendering = false
    }
    
    private func createParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineHeightMultiple = 1.15
        return paragraphStyle
    }
    
    private func applyMarkdownStyling(to attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        
        // Headers
        applyHeaderStyling(to: attributedString, text: text)
        
        // Bold text
        applyBoldStyling(to: attributedString, text: text)
        
        // Italic text
        applyItalicStyling(to: attributedString, text: text)
        
        // Code blocks and inline code
        applyCodeStyling(to: attributedString, text: text)
        
        // Links and wikilinks
        applyLinkStyling(to: attributedString, text: text)
        
        // Lists
        applyListStyling(to: attributedString, text: text)
        
        // Tags
        applyTagStyling(to: attributedString, text: text)
    }
    
    private func applyHeaderStyling(to attributedString: NSMutableAttributedString, text: String) {
        // H1 - # Header (smaller like Obsidian)
        let h1Pattern = "^(#{1})\\s+(.+)$"
        applyPattern(h1Pattern, to: attributedString, text: text) { match, range in
            let headerRange = NSRange(location: range.location + 2, length: range.length - 2)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 18),
                NSAttributedString.Key.foregroundColor: NSColor.white
            ], range: headerRange)
            
            // Style the # symbol
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray,
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 2))
        }
        
        // H2 - ## Header (smaller like Obsidian)
        let h2Pattern = "^(#{2})\\s+(.+)$"
        applyPattern(h2Pattern, to: attributedString, text: text) { match, range in
            let headerRange = NSRange(location: range.location + 3, length: range.length - 3)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: NSColor.white
            ], range: headerRange)
            
            // Style the ## symbols
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray,
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 3))
        }
        
        // H3 - ### Header (smaller like Obsidian)
        let h3Pattern = "^(#{3})\\s+(.+)$"
        applyPattern(h3Pattern, to: attributedString, text: text) { match, range in
            let headerRange = NSRange(location: range.location + 4, length: range.length - 4)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor: NSColor.white
            ], range: headerRange)
            
            // Style the ### symbols
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray,
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 4))
        }
    }
    
    private func applyBoldStyling(to attributedString: NSMutableAttributedString, text: String) {
        let boldPattern = "\\*\\*([^*]+)\\*\\*"
        let cursorPosition = selectedRange().location
        
        applyPattern(boldPattern, to: attributedString, text: text) { match, range in
            // Style the content as bold
            let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 14),
                NSAttributedString.Key.foregroundColor: NSColor.white
            ], range: contentRange)
            
            // Hide or show markers based on cursor position
            let isNearCursor = cursorPosition >= range.location && cursorPosition <= range.location + range.length
            let markerAlpha: CGFloat = isNearCursor ? 0.8 : 0.3
            
            // Style the ** markers as gray with varying opacity
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 2))
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location + range.length - 2, length: 2))
        }
    }
    
    private func applyItalicStyling(to attributedString: NSMutableAttributedString, text: String) {
        let italicPattern = "(?<!\\*)\\*([^*]+)\\*(?!\\*)"  // Avoid matching ** bold patterns
        let cursorPosition = selectedRange().location
        
        applyPattern(italicPattern, to: attributedString, text: text) { match, range in
            // Style the content as italic
            let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14).italic(),
                NSAttributedString.Key.foregroundColor: NSColor.white
            ], range: contentRange)
            
            // Hide or show markers based on cursor position
            let isNearCursor = cursorPosition >= range.location && cursorPosition <= range.location + range.length
            let markerAlpha: CGFloat = isNearCursor ? 0.8 : 0.3
            
            // Style the * markers as gray with varying opacity
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 1))
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location + range.length - 1, length: 1))
        }
    }
    
    private func applyCodeStyling(to attributedString: NSMutableAttributedString, text: String) {
        let cursorPosition = selectedRange().location
        
        // Inline code
        let inlineCodePattern = "`([^`]+)`"
        applyPattern(inlineCodePattern, to: attributedString, text: text) { match, range in
            // Style the content as code
            let contentRange = NSRange(location: range.location + 1, length: range.length - 2)
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                NSAttributedString.Key.foregroundColor: NSColor.systemRed,
                NSAttributedString.Key.backgroundColor: NSColor.gray.withAlphaComponent(0.15)
            ], range: contentRange)
            
            // Hide or show markers based on cursor position
            let isNearCursor = cursorPosition >= range.location && cursorPosition <= range.location + range.length
            let markerAlpha: CGFloat = isNearCursor ? 0.8 : 0.4
            
            // Style the ` markers as gray
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location, length: 1))
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha),
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12)
            ], range: NSRange(location: range.location + range.length - 1, length: 1))
        }
        
        // Code blocks
        let codeBlockPattern = "```([\\s\\S]*?)```"
        applyPattern(codeBlockPattern, to: attributedString, text: text) { match, range in
            // Style the entire code block
            attributedString.addAttributes([
                NSAttributedString.Key.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                NSAttributedString.Key.foregroundColor: NSColor.systemGreen,
                NSAttributedString.Key.backgroundColor: NSColor.gray.withAlphaComponent(0.1)
            ], range: range)
            
            // Style the ``` markers
            let markerAlpha: CGFloat = 0.6
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha)
            ], range: NSRange(location: range.location, length: 3))
            if range.length > 6 {
                attributedString.addAttributes([
                    NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(markerAlpha)
                ], range: NSRange(location: range.location + range.length - 3, length: 3))
            }
        }
    }
    
    private func applyLinkStyling(to attributedString: NSMutableAttributedString, text: String) {
        // Wikilinks [[Note Name]]
        let wikilinkPattern = "\\[\\[([^\\]]+)\\]\\]"
        applyPattern(wikilinkPattern, to: attributedString, text: text) { match, range in
            // Style the content as a link
            let contentRange = NSRange(location: range.location + 2, length: range.length - 4)
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.systemBlue,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: contentRange)
            
            // Style the [[ ]] markers as gray
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(0.6)
            ], range: NSRange(location: range.location, length: 2))
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray.withAlphaComponent(0.6)
            ], range: NSRange(location: range.location + range.length - 2, length: 2))
        }
    }
    
    private func applyListStyling(to attributedString: NSMutableAttributedString, text: String) {
        let listPattern = "^([-*])\\s+(.+)$"
        applyPattern(listPattern, to: attributedString, text: text) { match, range in
            // Style the bullet point
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.gray
            ], range: NSRange(location: range.location, length: 2))
        }
    }
    
    private func applyTagStyling(to attributedString: NSMutableAttributedString, text: String) {
        let tagPattern = "#([a-zA-Z0-9_-]+)"
        applyPattern(tagPattern, to: attributedString, text: text) { match, range in
            attributedString.addAttributes([
                NSAttributedString.Key.foregroundColor: NSColor.systemOrange,
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14, weight: .medium)
            ], range: range)
        }
    }
    
    private func applyPattern(_ pattern: String, to attributedString: NSMutableAttributedString, text: String, handler: (NSTextCheckingResult, NSRange) -> Void) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                handler(match, match.range)
            }
        } catch {
            print("Regex error: \(error)")
        }
    }
}

extension NSFont {
    func italic() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}