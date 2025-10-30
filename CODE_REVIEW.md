# Code Review - Strontium Notes

**Review Date:** October 30, 2025  
**Reviewer:** Kiro AI  
**Project:** Strontium Notes - Obsidian-inspired note-taking app for macOS

---

## Executive Summary

Strontium Notes is a well-structured SwiftUI application with a clean architecture following protocol-oriented design. The codebase demonstrates good separation of concerns with distinct service, model, view, and utility layers. However, there are several areas requiring attention including error handling, performance optimization, and incomplete implementations.

### Overall Assessment

| Category | Rating | Notes |
|----------|--------|-------|
| Architecture | ⭐⭐⭐⭐ | Clean separation of concerns, protocol-based design |
| Code Quality | ⭐⭐⭐ | Generally good, but needs consistency improvements |
| Error Handling | ⭐⭐⭐ | Good error types, but inconsistent implementation |
| Performance | ⭐⭐ | Several potential bottlenecks identified |
| Testing | ⭐ | Minimal test coverage |
| Documentation | ⭐⭐⭐⭐ | Excellent developer guide, good inline comments |

---

## Critical Issues

### 🔴 High Priority

- [ ] **Memory Leaks in FileSystemWatcher** - FSEventStream not properly released in all scenarios
- [ ] **Thread Safety Issues** - Multiple services access shared state without proper synchronization
- [ ] **Unbounded Search Index** - Search index grows indefinitely without cleanup
- [ ] **Missing Error Recovery** - Many async operations lack proper error handling
- [ ] **File System Race Conditions** - No locking mechanism for concurrent file operations

### 🟡 Medium Priority

- [ ] **Inefficient Vault Scanning** - Full vault rescan on every refresh
- [ ] **No Pagination** - All notes loaded into memory at once
- [ ] **Duplicate Code** - Similar markdown parsing logic in multiple places
- [ ] **Weak Type Safety** - `AnyCodable` wrapper loses type information
- [ ] **Missing Validation** - User input not validated before file operations

### 🟢 Low Priority

- [ ] **Inconsistent Naming** - Mix of "Obsidian" and "Strontium" prefixes
- [ ] **Unused Mock Data** - Mock data system still present in production code
- [ ] **Magic Numbers** - Hard-coded values throughout the codebase
- [ ] **Missing Accessibility** - No VoiceOver support or accessibility labels

---

## Detailed Analysis

## 1. Architecture & Design

### ✅ Strengths

- **Protocol-Oriented Design**: Clean separation between protocols and implementations
- **MVVM Pattern**: Well-implemented with clear separation of concerns
- **Service Layer**: Good abstraction of business logic
- **Combine Integration**: Proper use of publishers for reactive updates

### ⚠️ Issues

#### 1.1 Mixed Responsibilities in AppViewModel

```swift
// AppViewModel.swift - Lines 50-100
// ISSUE: AppViewModel is doing too much
class AppViewModel: ObservableObject {
    // Service management
    let vaultManager: VaultManager
    let noteManager: NoteManager
    // ... 6 more services
    
    // UI State
    @Published var showCommandPalette = false
    @Published var showingPreferences = false
    // ... 15 more UI properties
    
    // Mock data (shouldn't be here)
    @Published var mockNotes: [Note] = []
    @Published var mockFolders: [Folder] = []
}
```

**Recommendation**: Split into separate view models:
- `VaultViewModel` - Vault operations
- `EditorViewModel` - Editor state
- `SearchViewModel` - Search functionality

#### 1.2 Service Initialization Order

```swift
// AppViewModel.swift - Lines 85-92
init() {
    self.vaultManager = VaultManager()
    self.noteManager = NoteManager()
    self.linkResolver = LinkResolver()
    // ISSUE: BacklinkManager depends on LinkResolver
    // but there's no guarantee of initialization order
    self.backlinkManager = BacklinkManager(linkResolver: linkResolver)
}
```

**Recommendation**: Use dependency injection container or factory pattern.

---

## 2. Services Layer

### 2.1 NoteManager

#### ✅ Strengths
- Clean async/await implementation
- Good error handling with typed errors
- Proper use of Combine publishers

#### ⚠️ Issues

**Issue: Race Condition in File Operations**

```swift
// NoteManager.swift - Lines 25-45
func createNote(title: String, content: String, in vault: Vault, folderPath: String?) async throws -> Note {
    let fileName = generateUniqueFileName(for: title, in: vault, folderPath: folderPath)
    // ISSUE: File could be created between uniqueness check and write
    let fileURL = vault.rootURL.appendingPathComponent(fullPath)
    
    // No atomic check-and-create operation
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
}
```

**Recommendation**: Use `FileManager.createFile(atPath:contents:attributes:)` with exclusive creation flag.

**Issue: Inefficient Frontmatter Parsing**

```swift
// NoteManager.swift - Lines 150-180
func parseFrontmatter(from content: String) -> ([String: Any], String) {
    let lines = content.components(separatedBy: .newlines)
    // ISSUE: Simplified YAML parser doesn't handle:
    // - Nested objects
    // - Arrays
    // - Multi-line values
    // - Quoted strings with colons
    
    for line in frontmatterLines {
        let parts = line.components(separatedBy: ": ")
        // ISSUE: Breaks on "title: My Note: A Story"
        if parts.count == 2 {
            frontmatter[key] = value
        }
    }
}
```

**Recommendation**: Use a proper YAML parsing library like `Yams`.

### 2.2 VaultManager

#### ⚠️ Issues

**Issue: Full Vault Rescan on Every Refresh**

```swift
// VaultManager.swift - Lines 120-160
private func scanVault(_ vault: inout Vault) async throws {
    vault.notes = []
    vault.folders = []
    // ISSUE: Rescans entire vault even if only one file changed
    let enumerator = fileManager.enumerator(at: rootURL, ...)
    
    while let fileURL = enumerator?.nextObject() as? URL {
        // Process every file
    }
}
```

**Recommendation**: Implement incremental updates using FileSystemWatcher events.

**Issue: Network Location Check is Insufficient**

```swift
// VaultManager.swift - Lines 35-40
// Check if it's a network location
if url.path.hasPrefix("/Volumes/") || url.path.contains("://") {
    throw VaultError.networkLocationNotSupported
}
// ISSUE: Doesn't catch SMB, AFP, or cloud storage locations
```

**Recommendation**: Use `URLResourceKey.volumeIsLocalKey` to properly detect network volumes.

### 2.3 SearchEngine

#### ⚠️ Issues

**Issue: Unbounded Index Growth**

```swift
// SearchEngine.swift - Lines 20-25
private var searchIndex: [UUID: SearchIndexEntry] = [:]
// ISSUE: Index never cleaned up
// ISSUE: No memory limit
// ISSUE: Stale entries not removed
```

**Recommendation**: Implement LRU cache with size limits and TTL.

**Issue: Inefficient Search Algorithm**

```swift
// SearchEngine.swift - Lines 30-80
func search(_ query: SearchQuery, in vault: Vault, maxResults: Int) async -> [SearchResult] {
    // ISSUE: O(n) search through all entries
    for entry in searchIndex.values {
        // ISSUE: Multiple string contains checks per entry
        let titleMatches = entry.title.localizedCaseInsensitiveContains(term)
        let contentMatches = entry.content.localizedCaseInsensitiveContains(term)
    }
}
```

**Recommendation**: Use inverted index for O(1) term lookup.

### 2.4 FileSystemWatcher

#### 🔴 Critical Issue: Memory Leak

```swift
// FileSystemWatcher.swift - Lines 20-30
deinit {
    if let stream = eventStream {
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}
// ISSUE: If deinit is never called (retain cycle), stream leaks
// ISSUE: No cleanup on app termination
```

**Recommendation**: Add explicit cleanup method and call in `applicationWillTerminate`.

---

## 3. Models

### 3.1 Note Model

#### ⚠️ Issues

**Issue: Inefficient Tag Extraction**

```swift
// Note.swift - Lines 50-60
private static func extractTags(from content: String) -> Set<String> {
    let tagPattern = #"#([a-zA-Z0-9_-]+)"#
    let regex = try! NSRegularExpression(pattern: tagPattern, options: [])
    // ISSUE: Force try! will crash on invalid regex
    // ISSUE: Regex compiled on every call
    // ISSUE: Doesn't handle #tag/subtag syntax
}
```

**Recommendation**: Cache compiled regex, handle errors, support nested tags.

**Issue: AnyCodable Type Erasure**

```swift
// Note.swift - Lines 70-110
struct AnyCodable: Codable {
    let value: Any
    // ISSUE: Loses type information
    // ISSUE: Limited type support
    // ISSUE: No way to recover original type safely
}
```

**Recommendation**: Use `Codable` enums with associated values or remove frontmatter from Note model.

### 3.2 Vault Model

#### ⚠️ Issues

**Issue: Mutable Arrays Without Synchronization**

```swift
// Vault.swift - Lines 10-20
struct Vault: Identifiable, Codable {
    var notes: [Note]  // ISSUE: Can be modified from multiple threads
    var folders: [Folder]  // ISSUE: No thread safety
}
```

**Recommendation**: Use `@Published` properties or actor isolation.

---

## 4. Views

### 4.1 ObsidianEditorView

#### ✅ Strengths
- Clean separation of editor modes
- Good use of SwiftUI animations
- Proper state management

#### ⚠️ Issues

**Issue: Duplicate Content State**

```swift
// ObsidianEditorView.swift - Lines 10-15
@ObservedObject var appViewModel: AppViewModel
@State private var editedContent: String = ""
// ISSUE: Two sources of truth for content
// ISSUE: Sync issues between editedContent and note.content
```

**Recommendation**: Use single source of truth with computed properties.

**Issue: Missing Debouncing**

```swift
// ObsidianEditorView.swift - Lines 100-105
.onChange(of: editedContent) { _, _ in
    isEditing = true
    // ISSUE: No debouncing - triggers on every keystroke
    // ISSUE: Could cause performance issues with large documents
}
```

**Recommendation**: Add debouncing with Combine's `.debounce()`.

### 4.2 NotionEditor

#### ⚠️ Issues

**Issue: iOS-Specific Code in macOS App**

```swift
// NotionEditor.swift - Lines 50-55
#if os(iOS)
let impactFeedback = UIImpactFeedbackGenerator(style: .light)
impactFeedback.impactOccurred()
#endif
// ISSUE: This is a macOS-only app
```

**Recommendation**: Remove iOS-specific code or use proper cross-platform abstractions.

**Issue: Inefficient Block Parsing**

```swift
// NotionEditor.swift - Lines 80-90
private func parseTextIntoBlocks() {
    let lines = text.components(separatedBy: .newlines)
    blocks = lines.compactMap { line in
        // ISSUE: Recreates all blocks on every text change
        // ISSUE: Loses block IDs, breaking animations
    }
}
```

**Recommendation**: Implement differential updates to preserve block identity.

---

## 5. Utilities

### 5.1 MarkdownParser

#### ⚠️ Issues

**Issue: Incomplete Markdown Support**

```swift
// MarkdownParser.swift - Lines 10-20
static func parse(_ markdown: String) -> AttributedString {
    var attributedString = AttributedString(markdown)
    // ISSUE: No actual parsing implemented
    // ISSUE: Comment says "simplified implementation"
    return attributedString
}
```

**Recommendation**: Implement proper markdown parsing or use library like `Down` or `MarkdownUI`.

**Issue: Word Count Doesn't Handle All Cases**

```swift
// MarkdownParser.swift - Lines 150-170
static func wordCount(_ markdown: String) -> Int {
    // Removes code blocks
    // Removes frontmatter
    // ISSUE: Doesn't remove:
    // - HTML tags
    // - Inline code
    // - URLs
    // - Markdown syntax characters
}
```

**Recommendation**: More comprehensive text extraction before counting.

### 5.2 ErrorHandler

#### ✅ Strengths
- Centralized error handling
- User-friendly messages
- Good recovery suggestions

#### ⚠️ Issues

**Issue: Debug-Only Logging**

```swift
// ErrorHandler.swift - Lines 25-30
static func log(_ error: Error, context: String = "") {
    #if DEBUG
    print("❌ Error in \(context): \(error.localizedDescription)")
    #endif
    // ISSUE: No logging in production
    // ISSUE: No crash reporting integration
}
```

**Recommendation**: Add production logging with privacy-safe implementation.

---

## 6. Performance Issues

### 6.1 Memory Usage

| Issue | Impact | Location |
|-------|--------|----------|
| All notes loaded at once | High | VaultManager.scanVault() |
| Search index unbounded | High | SearchEngine |
| No image lazy loading | Medium | AttachmentManager |
| Duplicate note content | Medium | AppViewModel.mockNotes |

### 6.2 CPU Usage

| Issue | Impact | Location |
|-------|--------|----------|
| Full vault rescan | High | VaultManager.refreshCurrentVault() |
| Regex compilation per call | Medium | Note.extractTags() |
| No search result caching | Medium | SearchEngine.search() |
| Block recreation on edit | Low | NotionEditor.parseTextIntoBlocks() |

### 6.3 Disk I/O

| Issue | Impact | Location |
|-------|--------|----------|
| No file read caching | High | NoteManager.loadNote() |
| Synchronous file operations | Medium | Multiple locations |
| No batch file operations | Low | VaultManager |

---

## 7. Security Concerns

### 7.1 File System Access

- [ ] **No path traversal validation** - User input not sanitized before file operations
- [ ] **No file size limits** - Could load arbitrarily large files
- [ ] **No permission checks** - Assumes file system access without verification

### 7.2 Data Validation

- [ ] **No input sanitization** - File names not validated for special characters
- [ ] **No content validation** - Markdown content not sanitized
- [ ] **No URL validation** - External links not validated

---

## 8. Testing

### Current State

```
Test Coverage: ~5%
Unit Tests: 2 placeholder files
Integration Tests: 0
UI Tests: 2 placeholder files
```

### Missing Test Coverage

- [ ] Service layer operations
- [ ] Error handling paths
- [ ] Concurrent operations
- [ ] File system edge cases
- [ ] Search functionality
- [ ] Link resolution
- [ ] Markdown parsing

---

## 9. Code Quality Issues

### 9.1 Naming Inconsistencies

```swift
// Mixed naming conventions
ObsidianEditorView  // "Obsidian" prefix
StrontiumNotesApp   // "Strontium" prefix
NotionEditor        // "Notion" prefix
```

**Recommendation**: Choose one naming scheme and apply consistently.

### 9.2 Magic Numbers

```swift
// Hard-coded values throughout
.frame(width: 280)  // Sidebar width
.debounce(for: .seconds(2))  // Debounce time
.prefix(10)  // Max suggestions
snippetLength: Int = 150  // Snippet length
```

**Recommendation**: Extract to constants with meaningful names.

### 9.3 TODO Comments

Found **23 TODO comments** in the codebase:

```swift
// TODO: Implement folder creation
// TODO: Implement proper folder-based note counting
// TODO: Implement note moving between folders
// TODO: Save the note
// TODO: Implement duplicate
// TODO: Implement delete
// TODO: Toggle preview mode
// TODO: Show note info
```

**Recommendation**: Create GitHub issues for all TODOs and prioritize implementation.

---

## 10. Recommendations

### Immediate Actions (This Sprint)

1. **Fix Memory Leak in FileSystemWatcher**
   - Add explicit cleanup method
   - Call cleanup in applicationWillTerminate
   - Add tests for proper cleanup

2. **Implement Proper Error Handling**
   - Add try-catch blocks to all async operations
   - Show user-friendly error messages
   - Add error recovery options

3. **Add Input Validation**
   - Validate file names before creation
   - Check file sizes before loading
   - Sanitize user input

4. **Remove Mock Data System**
   - Delete mockNotes and mockFolders
   - Use real vault data only
   - Clean up related code

### Short Term (Next 2-4 Weeks)

1. **Optimize Vault Scanning**
   - Implement incremental updates
   - Use FileSystemWatcher for change detection
   - Add caching layer

2. **Improve Search Performance**
   - Implement inverted index
   - Add result caching
   - Implement pagination

3. **Add Comprehensive Tests**
   - Unit tests for all services
   - Integration tests for workflows
   - UI tests for critical paths

4. **Refactor AppViewModel**
   - Split into focused view models
   - Reduce property count
   - Improve testability

### Long Term (Next Quarter)

1. **Performance Optimization**
   - Implement lazy loading
   - Add pagination for large vaults
   - Optimize memory usage

2. **Enhanced Features**
   - Complete TODO implementations
   - Add undo/redo support
   - Implement version history

3. **Production Readiness**
   - Add crash reporting
   - Implement analytics
   - Add user feedback system

4. **Accessibility**
   - Add VoiceOver support
   - Implement keyboard navigation
   - Add accessibility labels

---

## 11. Code Metrics

### Complexity Analysis

| File | Lines | Complexity | Maintainability |
|------|-------|------------|-----------------|
| AppViewModel.swift | 450 | High | Medium |
| VaultManager.swift | 200 | Medium | Good |
| NoteManager.swift | 250 | Medium | Good |
| SearchEngine.swift | 300 | High | Medium |
| ObsidianEditorView.swift | 350 | High | Medium |
| NotionEditor.swift | 280 | Medium | Good |

### Dependencies

```
Total Files: 45
Swift Files: 42
Test Files: 3
External Dependencies: 0 (Good!)
Internal Dependencies: High coupling in AppViewModel
```

---

## 12. Best Practices Violations

### Violated Principles

- **Single Responsibility**: AppViewModel handles too many concerns
- **DRY**: Duplicate markdown parsing logic
- **YAGNI**: Mock data system in production code
- **Fail Fast**: Silent error handling with try?
- **Separation of Concerns**: UI code mixed with business logic

### Swift-Specific Issues

- Force unwrapping with `try!` in production code
- Implicit force unwrapping in some locations
- Missing `@MainActor` annotations on some UI code
- Inconsistent use of `async/await` vs Combine

---

## Conclusion

Strontium Notes demonstrates a solid foundation with clean architecture and good separation of concerns. The protocol-oriented design and use of modern Swift features (async/await, Combine) are commendable. However, the application requires significant work in error handling, performance optimization, and test coverage before it's production-ready.

### Priority Matrix

```
High Impact, High Effort:
- Optimize vault scanning
- Implement proper search indexing
- Add comprehensive test suite

High Impact, Low Effort:
- Fix memory leaks
- Add input validation
- Remove mock data system

Low Impact, High Effort:
- Refactor AppViewModel
- Implement accessibility

Low Impact, Low Effort:
- Fix naming inconsistencies
- Extract magic numbers
- Add documentation
```

### Final Recommendation

**Status**: Not production-ready  
**Estimated Work**: 4-6 weeks to production readiness  
**Risk Level**: Medium

Focus on fixing critical issues (memory leaks, error handling) before adding new features. The architecture is sound, but implementation needs refinement.

---

**Review Completed**: October 30, 2025  
**Next Review**: After critical issues are addressed
