//
//  VaultManagerProtocol.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation
import Combine

/// Protocol defining the vault management interface
protocol VaultManagerProtocol: ObservableObject {
    /// Current active vault
    var currentVault: Vault? { get }
    
    /// List of recently accessed vaults
    var recentVaults: [VaultReference] { get }
    
    /// Publisher for vault changes
    var vaultDidChange: AnyPublisher<Vault?, Never> { get }
    
    /// Open a vault at the specified URL
    /// - Parameter url: The file system URL of the vault directory
    /// - Returns: The opened vault
    /// - Throws: VaultError if the vault cannot be opened
    func openVault(at url: URL) async throws -> Vault
    
    /// Close the specified vault
    /// - Parameter vault: The vault to close
    func closeVault(_ vault: Vault)
    
    /// Get the currently active vault
    /// - Returns: The current vault, or nil if no vault is open
    func getCurrentVault() -> Vault?
    
    /// Get the list of recently accessed vaults
    /// - Returns: Array of vault references sorted by last access date
    func getRecentVaults() -> [VaultReference]
    
    /// Create a new vault at the specified location
    /// - Parameters:
    ///   - name: The name of the new vault
    ///   - url: The file system URL where the vault should be created
    /// - Returns: The newly created vault
    /// - Throws: VaultError if the vault cannot be created
    func createVault(name: String, at url: URL) async throws -> Vault
    
    /// Refresh the current vault by rescanning the file system
    /// - Throws: VaultError if the vault cannot be refreshed
    func refreshCurrentVault() async throws
    
    /// Check if a directory is a valid vault
    /// - Parameter url: The directory URL to check
    /// - Returns: True if the directory can be used as a vault
    func isValidVault(at url: URL) -> Bool
}

/// Errors that can occur during vault operations
enum VaultError: LocalizedError {
    case directoryNotFound
    case permissionDenied
    case invalidVaultStructure
    case vaultAlreadyOpen
    case corruptedMetadata
    case diskSpaceInsufficient
    case networkLocationNotSupported
    
    var errorDescription: String? {
        switch self {
        case .directoryNotFound:
            return "The specified directory could not be found."
        case .permissionDenied:
            return "Permission denied. Please check that you have read and write access to this directory."
        case .invalidVaultStructure:
            return "The directory does not contain a valid vault structure."
        case .vaultAlreadyOpen:
            return "This vault is already open."
        case .corruptedMetadata:
            return "The vault metadata is corrupted and cannot be read."
        case .diskSpaceInsufficient:
            return "Insufficient disk space to create or open the vault."
        case .networkLocationNotSupported:
            return "Network locations are not supported for vaults."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            return "Please select a different directory or create the directory first."
        case .permissionDenied:
            return "Try selecting a directory in your home folder or Documents folder."
        case .invalidVaultStructure:
            return "Select an existing vault directory or create a new vault."
        case .vaultAlreadyOpen:
            return "Close the existing vault first or select a different directory."
        case .corruptedMetadata:
            return "Try refreshing the vault or recreating the metadata."
        case .diskSpaceInsufficient:
            return "Free up disk space and try again."
        case .networkLocationNotSupported:
            return "Copy the vault to a local directory first."
        }
    }
}