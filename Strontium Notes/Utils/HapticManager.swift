//
//  HapticManager.swift
//  Strontium Notes
//
//  Created by Kiro on 29/10/25.
//

import Foundation

#if canImport(UIKit)
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    func notificationSuccess() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func notificationError() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

#else
// macOS fallback - no haptics available
class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    func lightImpact() { /* No haptics on macOS */ }
    func mediumImpact() { /* No haptics on macOS */ }
    func heavyImpact() { /* No haptics on macOS */ }
    func selectionChanged() { /* No haptics on macOS */ }
    func notificationSuccess() { /* No haptics on macOS */ }
    func notificationError() { /* No haptics on macOS */ }
}
#endif

// SwiftUI View Extension for easy haptic feedback
import SwiftUI

extension View {
    func hapticFeedback(_ style: HapticStyle = .light) -> some View {
        self.onTapGesture {
            switch style {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .selection:
                HapticManager.shared.selectionChanged()
            }
        }
    }
}

enum HapticStyle {
    case light, medium, heavy, selection
}