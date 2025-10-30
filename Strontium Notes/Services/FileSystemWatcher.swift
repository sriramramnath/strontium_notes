//
//  FileSystemWatcher.swift
//  Strontium Notes
//
//  Created by Kiro on 30/10/25.
//

import Foundation
import Combine

/// Monitors file system changes in a vault directory
class FileSystemWatcher: ObservableObject {
    @Published private(set) var lastChangeDate = Date()
    
    private let fileChangedSubject = PassthroughSubject<URL, Never>()
    var fileChanged: AnyPublisher<URL, Never> {
        fileChangedSubject.eraseToAnyPublisher()
    }
    
    private var eventStream: FSEventStreamRef?
    private var watchedURL: URL?
    private let fileManager = FileManager.default
    
    deinit {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
    
    /// Start watching a directory for changes
    func startWatching(url: URL) {
        stopWatching()
        
        watchedURL = url
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { (
            streamRef,
            clientCallBackInfo,
            numEvents,
            eventPaths,
            eventFlags,
            eventIds
        ) in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FileSystemWatcher>.fromOpaque(info).takeUnretainedValue()
            
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
            
            for i in 0..<numEvents {
                let path = paths[i]
                // let flags = eventFlags[i] // Unused for now
                
                // Check if it's a markdown file
                if path.hasSuffix(".md") {
                    let fileURL = URL(fileURLWithPath: path)
                    
                    Task { @MainActor in
                        watcher.fileChangedSubject.send(fileURL)
                        watcher.lastChangeDate = Date()
                    }
                }
            }
        }
        
        let pathsToWatch = [url.path] as CFArray
        let latency: CFTimeInterval = 1.0 // 1 second latency
        
        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        
        if let stream = eventStream {
            let queue = DispatchQueue.global(qos: .background)
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }
    
    /// Stop watching the current directory
    func stopWatching() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
        watchedURL = nil
    }
    
    /// Check if currently watching a directory
    var isWatching: Bool {
        return eventStream != nil
    }
}
