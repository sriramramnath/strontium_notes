//
//  AttachmentManager.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import UniformTypeIdentifiers
import Combine

/// Manages file attachments and embeddings
@MainActor
class AttachmentManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private let fileManager = FileManager.default
    
    /// Copy a file to the vault's attachments folder
    func addAttachment(fileURL: URL, to vault: Vault) throws -> String {
        let attachmentsFolder = vault.rootURL.appendingPathComponent(vault.settings.attachmentsFolderName)
        
        // Create attachments folder if it doesn't exist
        if !fileManager.fileExists(atPath: attachmentsFolder.path) {
            try fileManager.createDirectory(at: attachmentsFolder, withIntermediateDirectories: true)
        }
        
        let fileName = fileURL.lastPathComponent
        let destinationURL = attachmentsFolder.appendingPathComponent(fileName)
        
        // Handle duplicate names
        var finalURL = destinationURL
        var counter = 1
        while fileManager.fileExists(atPath: finalURL.path) {
            let nameWithoutExt = fileURL.deletingPathExtension().lastPathComponent
            let ext = fileURL.pathExtension
            let newName = "\(nameWithoutExt)-\(counter).\(ext)"
            finalURL = attachmentsFolder.appendingPathComponent(newName)
            counter += 1
        }
        
        try fileManager.copyItem(at: fileURL, to: finalURL)
        
        // Return relative path
        return "\(vault.settings.attachmentsFolderName)/\(finalURL.lastPathComponent)"
    }
    
    /// Get the full URL for an attachment
    func getAttachmentURL(relativePath: String, in vault: Vault) -> URL {
        return vault.rootURL.appendingPathComponent(relativePath)
    }
    
    /// Check if a file is an image
    func isImage(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }
    
    /// Parse image embeds from markdown content
    func parseImageEmbeds(from content: String) -> [ImageEmbed] {
        var embeds: [ImageEmbed] = []
        
        // Pattern for ![[image.png]] or ![[path/to/image.png]]
        let pattern = #"!\[\[([^\]]+)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return embeds
        }
        
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let pathRange = match.range(at: 1)
            guard pathRange.location != NSNotFound else { continue }
            
            let path = nsString.substring(with: pathRange)
            let embed = ImageEmbed(path: path, range: match.range)
            embeds.append(embed)
        }
        
        return embeds
    }
    
    /// Parse file links from markdown content
    func parseFileLinks(from content: String) -> [FileLink] {
        var links: [FileLink] = []
        
        // Pattern for [[file.pdf]] or [[path/to/file.pdf]]
        let pattern = #"\[\[([^\]]+\.(pdf|docx|xlsx|pptx|zip|txt))\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return links
        }
        
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let pathRange = match.range(at: 1)
            guard pathRange.location != NSNotFound else { continue }
            
            let path = nsString.substring(with: pathRange)
            let link = FileLink(path: path, range: match.range)
            links.append(link)
        }
        
        return links
    }
}

/// Represents an embedded image
struct ImageEmbed: Identifiable {
    let id = UUID()
    let path: String
    let range: NSRange
}

/// Represents a file link
struct FileLink: Identifiable {
    let id = UUID()
    let path: String
    let range: NSRange
}
