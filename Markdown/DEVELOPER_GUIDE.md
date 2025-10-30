# Developer Guide - Strontium Notes

## Quick Start

### Opening a Vault

```swift
let appViewModel = AppViewModel()

// Open existing vault
await appViewModel.openVault(at: vaultURL)

// Create new vault
await appViewModel.createVault(name: "My Vault", at: parentURL)
```

### Working with Notes

```swift
// Create a note
appViewModel.createNewNote()

// Save a note
if let note = appViewModel.selectedNote {
    await appViewModel.saveNote(note)
}

// Delete a note
if let note = appViewModel.selectedNote {
    await appViewModel.deleteNote(note)
}

// Rename a note
if let note = appViewModel.selectedNote {
    await appViewModel.renameNote(note, to: "New Title")
}
```

### Searching

```swift
// Simple search
let results = await appViewModel.searchNotes(query: "search term")

// Advanced search with operators
let results = await appViewModel.searchNotes(query: "term tag:important -exclude")
```

### Working with Tags

```swift
// Get all tags
let tags = appViewModel.getAllTags()

// Get notes with specific tag
let notes = appViewModel.getNotesWithTag("important")
```

### Working with Links

```swift
// Get backlinks for a note
if let note = appViewModel.selectedNote {
    let backlinks = appViewModel.getBacklinks(for: note)
}

// Parse wikilinks from content
let links = appViewModel.linkResolver.parseWikiLinks(
    from: content,
    sourceNoteID: noteID
)
```

## Service Architecture

### VaultManager

Manages vault lifecycle and file system operations.

```swift
let vaultManager = VaultManager()

// Open vault
let vault = try await vaultManager.openVault(at: url)

// Create vault
let vault = try await vaultManager.createVault(name: "My Vault", at: url)

// Refresh vault (rescan files)
try await vaultManager.refreshCurrentVault()

// Close vault
vaultManager.closeVault(vault)
```

### NoteManager

Handles all note CRUD operations.

```swift
let noteManager = NoteManager()

// Create note
let note = try await noteManager.createNote(
    title: "My Note",
    content: "# Content",
    in: vault,
    folderPath: nil
)

// Load note
let note = try await noteManager.loadNote(from: filePath)

// Update note
let updated = try await noteManager.updateNote(note, with: newContent)

// Delete note
try await noteManager.deleteNote(note)

// Parse frontmatter
let (frontmatter, content) = noteManager.parseFrontmatter(from: markdown)
```

### LinkResolver

Parses and resolves wikilinks.

```swift
let linkResolver = LinkResolver()

// Parse wikilinks
let links = linkResolver.parseWikiLinks(from: content, sourceNoteID: id)

// Resolve links to actual notes
let resolved = await linkResolver.resolveLinks(links, in: vault)

// Update links when note is renamed
let updated = try await linkResolver.updateLinksForRenamedNote(
    oldTitle: "Old",
    newTitle: "New",
    in: vault
)

// Find broken links
let broken = await linkResolver.validateLinks(in: vault)
```

### BacklinkManager

Tracks backlinks and unlinked mentions.

```swift
let backlinkManager = BacklinkManager(linkResolver: linkResolver)

// Get backlinks
let backlinks = backlinkManager.getBacklinks(for: noteID, in: vault)

// Find unlinked mentions
let mentions = await backlinkManager.findUnlinkedMentions(
    of: "Note Title",
    targetNoteID: id,
    in: vault
)

// Convert mention to link
let updated = try await backlinkManager.convertMentionToLink(mention, in: vault)
```

### SearchEngine

Full-text search with indexing.

```swift
let searchEngine = SearchEngine()

// Build index
await searchEngine.buildIndex(for: vault)

// Search
let query = SearchQuery(rawQuery: "term tag:important -exclude")
let results = await searchEngine.search(query, in: vault, maxResults: 50)

// Quick search
let results = await searchEngine.quickSearch("term", in: vault)

// Update index for note
await searchEngine.updateIndex(for: note, in: vault)
```

### TagManager

Manages tags across the vault.

```swift
let tagManager = TagManager()

// Get all tags
let tags = tagManager.getAllTags(in: vault)

// Get notes with tag
let notes = tagManager.getNotesWithTag("important", in: vault)

// Rename tag
let updated = try await tagManager.renameTag(
    from: "old",
    to: "new",
    in: vault
)

// Rebuild index
await tagManager.rebuildTagIndex(for: vault)
```

## Utilities

### MarkdownParser

Parse markdown content.

```swift
// Extract headers
let headers = MarkdownParser.extractHeaders(markdown)

// Extract code blocks
let blocks = MarkdownParser.extractCodeBlocks(markdown)

// Extract tasks
let tasks = MarkdownParser.extractTasks(markdown)

// Extract links
let links = MarkdownParser.extractLinks(markdown)

// Count words
let count = MarkdownParser.wordCount(markdown)
```

### FileSystemWatcher

Monitor vault for external changes.

```swift
let watcher = FileSystemWatcher()

// Start watching
watcher.startWatching(url: vaultURL)

// Observe changes
watcher.fileChanged
    .sink { url in
        print("File changed: \(url)")
    }
    .store(in: &cancellables)

// Stop watching
watcher.stopWatching()
```

### ErrorHandler

Handle errors gracefully.

```swift
// Get user-friendly message
let message = ErrorHandler.userMessage(for: error)

// Get recovery suggestion
let suggestion = ErrorHandler.recoverySuggestion(for: error)

// Log error
ErrorHandler.log(error, context: "operation name")

// Use in SwiftUI
.errorAlert(error: $error, isPresented: $showError)
```

### ThemeManager

Manage app theme.

```swift
let themeManager = ThemeManager()

// Set theme
themeManager.setTheme(.light)
themeManager.setTheme(.dark)
themeManager.setTheme(nil) // System

// Use in SwiftUI
.environmentObject(themeManager)
.preferredColorScheme(themeManager.preferredColorScheme)
```

## Data Models

### Note

```swift
let note = Note(
    filePath: "path/to/note.md",
    title: "My Note",
    content: "# Content",
    frontmatter: ["key": "value"]
)

// Properties
note.id // UUID
note.title // String
note.content // String
note.tags // Set<String>
note.filePath // String
note.fileName // String (computed)
note.isMarkdown // Bool (computed)

// Methods
let links = note.getLinks() // [String]
```

### Vault

```swift
let vault = Vault(
    name: "My Vault",
    rootURL: url,
    settings: VaultSettings()
)

// Properties
vault.id // UUID
vault.name // String
vault.rootURL // URL
vault.notes // [Note]
vault.folders // [Folder]
vault.settings // VaultSettings
```

### WikiLink

```swift
let link = WikiLink(
    sourceNoteID: sourceID,
    targetNoteName: "Target Note",
    linkText: "Display Text",
    range: range
)

// Properties
link.isResolved // Bool
link.isBroken // Bool
link.resolvedTargetID // UUID?
```

### SearchQuery

```swift
let query = SearchQuery(rawQuery: "term tag:important -exclude path:folder")

// Properties
query.terms // [String]
query.tags // [String]
query.excludedTerms // [String]
query.pathFilters // [String]
query.isExactPhrase // Bool
```

## Error Handling

All service methods throw typed errors:

```swift
do {
    let vault = try await vaultManager.openVault(at: url)
} catch VaultError.directoryNotFound {
    // Handle missing directory
} catch VaultError.permissionDenied {
    // Handle permission error
} catch {
    // Handle other errors
}
```

### VaultError Cases
- `directoryNotFound`
- `permissionDenied`
- `invalidVaultStructure`
- `vaultAlreadyOpen`
- `corruptedMetadata`
- `diskSpaceInsufficient`
- `networkLocationNotSupported`

### NoteError Cases
- `fileNotFound`
- `permissionDenied`
- `invalidContent`
- `duplicateTitle`
- `corruptedFile`
- `diskSpaceInsufficient`
- `invalidFileName`
- `frontmatterParsingFailed`

## Best Practices

### 1. Always Use Async/Await

```swift
// Good
Task {
    await appViewModel.saveNote(note)
}

// Bad
appViewModel.saveNote(note) // Won't compile
```

### 2. Handle Errors

```swift
// Good
do {
    try await noteManager.deleteNote(note)
} catch {
    ErrorHandler.log(error, context: "deleteNote")
    showError = true
}

// Bad
try? await noteManager.deleteNote(note) // Silently fails
```

### 3. Update Indexes

```swift
// After creating/updating a note
await searchEngine.updateIndex(for: note, in: vault)
await tagManager.updateTagIndex(for: note, in: vault)
await backlinkManager.updateBacklinks(for: note, in: vault)
```

### 4. Refresh Vault After Changes

```swift
// After file system operations
try await vaultManager.refreshCurrentVault()
```

### 5. Use Combine for Reactive Updates

```swift
vaultManager.$currentVault
    .sink { vault in
        // React to vault changes
    }
    .store(in: &cancellables)
```

## Testing

### Unit Tests

```swift
@Test func testNoteCreation() async throws {
    let note = Note(
        filePath: "test.md",
        title: "Test",
        content: "# Test"
    )
    #expect(note.title == "Test")
}
```

### Integration Tests

```swift
@Test func testVaultOperations() async throws {
    let manager = VaultManager()
    let vault = try await manager.createVault(name: "Test", at: tempURL)
    #expect(vault.name == "Test")
}
```

## Performance Tips

1. **Build search index once** - Don't rebuild on every search
2. **Use debouncing** - For file watcher and search input
3. **Lazy load** - For large note lists (not yet implemented)
4. **Cache results** - For frequently accessed data
5. **Profile regularly** - Use Instruments to find bottlenecks

## Common Patterns

### Creating a New Feature

1. Define protocol in `Services/`
2. Implement concrete class
3. Add to AppViewModel
4. Wire up in UI
5. Add tests
6. Update documentation

### Adding a New View

1. Create view file in `Views/`
2. Use `@EnvironmentObject` for AppViewModel
3. Use adaptive colors from ColorScheme
4. Add error handling
5. Test with different themes

### Handling User Actions

1. Capture action in view
2. Call AppViewModel method
3. AppViewModel calls service
4. Service performs operation
5. Service publishes change
6. UI updates automatically

## Debugging

### Enable Debug Logging

```swift
#if DEBUG
ErrorHandler.log(error, context: "operation")
#endif
```

### Check File System

```swift
print("Vault path: \(vault.rootURL.path)")
print("Notes count: \(vault.notes.count)")
print("Folders count: \(vault.folders.count)")
```

### Monitor Changes

```swift
fileSystemWatcher.fileChanged
    .sink { url in
        print("Changed: \(url)")
    }
    .store(in: &cancellables)
```

## Resources

- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [FileManager](https://developer.apple.com/documentation/foundation/filemanager)
- [FSEvents](https://developer.apple.com/documentation/coreservices/file_system_events)
