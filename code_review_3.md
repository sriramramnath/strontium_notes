# Code Review 3 – Strontium Notes

**Date:** October 31, 2025  
**Reviewer:** GPT-5 Codex

---

## Summary
- The note persistence pipeline breaks once a vault is opened because the service layer mixes relative and absolute paths, so core actions such as save/rename/delete never hit the intended files.
- Note identity is not stable across rescans, which invalidates caches and prevents the UI from reconciling edits after the filesystem watcher refreshes data.
- Long-running filesystem work is performed on the main actor, creating visible hangs on moderately sized vaults.

---

## 🔴 Critical Findings

### 1. Relative vs absolute note paths break all persistence operations
- **Impact:** `saveNote`, `renameNote`, `deleteNote`, `moveNote`, and `loadNote` either target the filesystem root or throw because the underlying file cannot be found. In practice you cannot modify an existing note inside a vault; every mutating call fails with `NSFileNoSuchFileError`/`permissionDenied`.
- **Details:** `VaultManager.scanVault` records each note using a **relative** path (`"subdir/Note.md"`). Every mutating API in `NoteManager` later feeds that value straight into `URL(fileURLWithPath:)`, which Foundation interprets as an **absolute** path (e.g. `/subdir/Note.md`). The same assumption appears in `loadNote(from:)`, so even read-only calls break when given a path produced by the scanner.
- **Evidence:** `Strontium Notes/Services/VaultManager.swift` populates notes with relative paths, while `Strontium Notes/Services/NoteManager.swift` derives file URLs directly from those values.
- **Recommendation:** Standardise on one representation. Either persist absolute paths (e.g. use `fileURL.path` when constructing `Note`) or require every `NoteManager` method to receive the owning `Vault` so it can resolve `vault.rootURL.appendingPathComponent(note.filePath)`. Add regression tests that open a vault, edit a note, and confirm file contents change on disk.

### 2. Note identifiers change on every refresh
- **Impact:** After `refreshCurrentVault()` runs (or the filesystem watcher triggers a rescan) each `Note` receives a brand-new `UUID`. Any cached structures (`SearchEngine` index, backlink cache, selected-note bindings, tag index, etc.) stop matching the refreshed data. For example, `AppViewModel.saveNote` cannot find the edited note inside `mockNotes` once the IDs diverge, so the UI silently stops reflecting changes.
- **Details:** `Note.init` generates a fresh `UUID` and `VaultManager.scanVault` recreates every note from scratch during each pass. Nothing preserves the previous identifier (e.g. hashing the file path), so identity is volatile.
- **Recommendation:** Derive `Note.id` from stable metadata (file path or inode) or store the ID alongside the file. Ensure caches use that stable identifier when rebuilding the vault.

---

## 🟡 Medium Findings

### 1. Vault rescans block the main thread
- `VaultManager` is annotated with `@MainActor`, and `scanVault` performs synchronous directory enumeration plus `String(contentsOf:)` for every markdown file. On a vault with a few hundred notes this freezes the UI for noticeable periods, especially because the filesystem watcher triggers the whole scan after each change. Move the scan work to a background actor/queue and publish results back to the main actor.

### 2. File metadata is fabricated
- `Note` sets `createdDate`, `modifiedDate`, and `fileSize` to the current time/content length whenever a note is materialised. Because vault rescans recreate every note, timestamps continually jump to “just now,” and sizes ignore actual attachments. Pull this metadata from `FileManager` attributes so UI surfaces show accurate information.

---

## 🟢 Low Observations

- `Note.extractTags` recompiles its regular expression and uses `try!`, which will crash the process if the pattern is ever edited incorrectly. Cache the regex and handle failures gracefully.
- `FileSystemWatcher` filters events with `path.hasSuffix(".md")` (case-sensitive), so changes to files with uppercase extensions (e.g. `README.MD`) never trigger rescans. Normalise the extension before filtering.

---

## Suggested Next Steps
- Fix the path-handling bug first; add integration tests for save/rename/delete to prevent regression.
- Stabilise note identity and update dependent caches to key off the new scheme.
- Offload vault scans to a background context and reuse file metadata instead of synthesising it.
- Follow up on the smaller observations once the above ship; they are low effort but still improve resilience.


