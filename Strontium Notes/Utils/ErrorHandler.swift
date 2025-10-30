//
//  ErrorHandler.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import SwiftUI

/// Centralized error handling and user-friendly error messages
struct ErrorHandler {
    
    /// Convert any error to a user-friendly message
    static func userMessage(for error: Error) -> String {
        if let vaultError = error as? VaultError {
            return vaultError.localizedDescription
        } else if let noteError = error as? NoteError {
            return noteError.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
    
    /// Get recovery suggestion for an error
    static func recoverySuggestion(for error: Error) -> String? {
        if let vaultError = error as? VaultError {
            return vaultError.recoverySuggestion
        } else if let noteError = error as? NoteError {
            return noteError.recoverySuggestion
        }
        return nil
    }
    
    /// Log error for debugging
    static func log(_ error: Error, context: String = "") {
        #if DEBUG
        print("❌ Error in \(context): \(error.localizedDescription)")
        if let suggestion = recoverySuggestion(for: error) {
            print("💡 Suggestion: \(suggestion)")
        }
        #endif
    }
}

/// View modifier for displaying errors
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented, presenting: error) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(ErrorHandler.userMessage(for: error))
                    
                    if let suggestion = ErrorHandler.recoverySuggestion(for: error) {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, isPresented: Binding<Bool>) -> some View {
        modifier(ErrorAlert(error: error, isPresented: isPresented))
    }
}
