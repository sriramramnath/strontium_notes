//
//  NotionEditor.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import SwiftUI

struct NotionEditor: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let onTextChange: (String) -> Void
    
    @State private var blocks: [NotionBlock] = []
    @State private var editingBlockId: UUID? = nil
    @FocusState private var isFieldFocused: Bool
    @State private var showingBlocks = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    NotionBlockView(
                        block: block,
                        isEditing: editingBlockId == block.id,
                        onEdit: { content in
                            updateBlock(block.id, with: content)
                        },
                        onStartEdit: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editingBlockId = block.id
                            }
                            isFieldFocused = true
                            // Add haptic feedback for editing
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            #endif
                        },
                        onEndEdit: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                editingBlockId = nil
                            }
                        },
                        onNewBlock: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                insertNewBlock(after: block.id)
                            }
                            // Add haptic feedback for new block
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            #endif
                        },
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                deleteBlock(block.id)
                            }
                            // Add haptic feedback for deletion
                            #if os(iOS)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                            #endif
                        }
                    )
                    .focused($isFieldFocused, equals: editingBlockId == block.id)
                    .opacity(showingBlocks ? 1 : 0)
                    .offset(y: showingBlocks ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.05), value: showingBlocks)
                }
                
                // Empty state - click to add first block
                if blocks.isEmpty {
                    Button {
                        addFirstBlock()
                    } label: {
                        HStack {
                            Text("Click here to start writing...")
                                .font(.system(size: 16))
                                .foregroundColor(.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
        }
        .background(Color.primaryBackground)
        .onAppear {
            parseTextIntoBlocks()
            withAnimation(.easeOut(duration: 0.6)) {
                showingBlocks = true
            }
        }
        .onChange(of: text) { _, newValue in
            if editingBlockId == nil {
                parseTextIntoBlocks()
            }
        }
    }
    
    private func parseTextIntoBlocks() {
        let lines = text.components(separatedBy: .newlines)
        blocks = lines.compactMap { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty && lines.count == 1 {
                return nil // Don't create empty blocks for single empty lines
            }
            return NotionBlock(content: line)
        }
        
        if blocks.isEmpty && !text.isEmpty {
            blocks = [NotionBlock(content: text)]
        }
    }
    
    private func updateBlock(_ id: UUID, with content: String) {
        if let index = blocks.firstIndex(where: { $0.id == id }) {
            blocks[index].content = content
            updateTextFromBlocks()
        }
    }
    
    private func insertNewBlock(after id: UUID) {
        if let index = blocks.firstIndex(where: { $0.id == id }) {
            let newBlock = NotionBlock(content: "")
            blocks.insert(newBlock, at: index + 1)
            editingBlockId = newBlock.id
            updateTextFromBlocks()
        }
    }
    
    private func deleteBlock(_ id: UUID) {
        if blocks.count > 1 {
            blocks.removeAll { $0.id == id }
            editingBlockId = nil
            updateTextFromBlocks()
        }
    }
    
    private func addFirstBlock() {
        let newBlock = NotionBlock(content: "")
        blocks.append(newBlock)
        editingBlockId = newBlock.id
        updateTextFromBlocks()
    }
    
    private func updateTextFromBlocks() {
        let newText = blocks.map { $0.content }.joined(separator: "\n")
        text = newText
        onTextChange(newText)
        isEditing = true
    }
}

struct NotionBlockView: View {
    let block: NotionBlock
    let isEditing: Bool
    let onEdit: (String) -> Void
    let onStartEdit: () -> Void
    let onEndEdit: () -> Void
    let onNewBlock: () -> Void
    let onDelete: () -> Void
    
    @State private var editingText: String = ""
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Content area
            VStack(alignment: .leading, spacing: 0) {
                if isEditing {
                    TextField("Type '/' for commands", text: $editingText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(fontForBlock)
                        .foregroundColor(.primaryText)
                        .onAppear {
                            editingText = block.content
                        }
                        .onSubmit {
                            onEdit(editingText)
                            onEndEdit()
                            onNewBlock()
                        }
                        .onChange(of: editingText) { _, newValue in
                            onEdit(newValue)
                        }
                } else {
                    if block.content.isEmpty {
                        // Empty block placeholder
                        Button {
                            onStartEdit()
                        } label: {
                            HStack {
                                Text("Type '/' for commands")
                                    .font(.system(size: 16))
                                    .foregroundColor(.tertiaryText)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Rendered content
                        Button {
                            onStartEdit()
                        } label: {
                            HStack {
                                renderedContent
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Hover menu (like Notion's ⋮⋮ handle)
            if isHovered && !isEditing {
                Button {
                    // Could add drag handle functionality here
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.secondaryBackground : Color.clear)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
        .scaleEffect(isHovered ? 1.002 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private var renderedContent: some View {
        Group {
            if block.content.hasPrefix("# ") {
                Text(String(block.content.dropFirst(2)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primaryText)
            } else if block.content.hasPrefix("## ") {
                Text(String(block.content.dropFirst(3)))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryText)
            } else if block.content.hasPrefix("### ") {
                Text(String(block.content.dropFirst(4)))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primaryText)
            } else if block.content.hasPrefix("- ") || block.content.hasPrefix("* ") {
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                    Text(String(block.content.dropFirst(2)))
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                }
            } else if block.content.hasPrefix("> ") {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color.secondaryText.opacity(0.3))
                        .frame(width: 3)
                    Text(String(block.content.dropFirst(2)))
                        .font(.system(size: 16))
                        .foregroundColor(.secondaryText)
                        .italic()
                }
            } else {
                Text(block.content)
                    .font(.system(size: 16))
                    .foregroundColor(.primaryText)
            }
        }
    }
    
    private var fontForBlock: Font {
        if block.content.hasPrefix("# ") {
            return .system(size: 32, weight: .bold)
        } else if block.content.hasPrefix("## ") {
            return .system(size: 24, weight: .semibold)
        } else if block.content.hasPrefix("### ") {
            return .system(size: 20, weight: .medium)
        } else {
            return .system(size: 16)
        }
    }
}

struct NotionBlock: Identifiable {
    let id = UUID()
    var content: String
    
    init(content: String) {
        self.content = content
    }
}