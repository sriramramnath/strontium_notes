//
//  Debouncer.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Utility class for debouncing rapid events
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let queue: DispatchQueue
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    /// Debounce a closure execution
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    /// Cancel any pending debounced action
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

/// SwiftUI View extension for debounced onChange
extension View {
    func onChangeDebounced<V: Equatable>(
        of value: V,
        delay: TimeInterval = 0.3,
        perform action: @escaping (V) -> Void
    ) -> some View {
        self.modifier(DebouncedChangeModifier(value: value, delay: delay, action: action))
    }
}

private struct DebouncedChangeModifier<V: Equatable>: ViewModifier {
    let value: V
    let delay: TimeInterval
    let action: (V) -> Void
    
    @State private var debouncer: Debouncer?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                debouncer = Debouncer(delay: delay)
            }
            .onChange(of: value) { _, newValue in
                debouncer?.debounce {
                    action(newValue)
                }
            }
    }
}
