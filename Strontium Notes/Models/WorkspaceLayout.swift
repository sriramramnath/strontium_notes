//
//  WorkspaceLayout.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation

/// Represents a workspace layout with multiple panes
struct WorkspaceLayout: Codable, Identifiable {
    let id: UUID
    var panes: [Pane]
    var splitDirection: SplitDirection
    
    init(id: UUID = UUID(), panes: [Pane] = [], splitDirection: SplitDirection = .horizontal) {
        self.id = id
        self.panes = panes
        self.splitDirection = splitDirection
    }
}

/// Represents a single pane in the workspace
struct Pane: Codable, Identifiable {
    let id: UUID
    var noteID: UUID?
    var width: CGFloat
    
    init(id: UUID = UUID(), noteID: UUID? = nil, width: CGFloat = 1.0) {
        self.id = id
        self.noteID = noteID
        self.width = width
    }
}

/// Direction for splitting panes
enum SplitDirection: String, Codable {
    case horizontal
    case vertical
}
