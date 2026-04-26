# Product Roadmap

## Phase 1: MVP — shipped

- Right-click any text file in Finder → **Services → Copy Contents to Clipboard**
- Auto-detects UTF-8, UTF-16 (with BOM), and Windows-1252 file encodings
- Sound feedback: Tink on success, Basso on failure
- Rejects non-text files (images, archives, executables) silently
- No UI, no menu-bar icon, no persistent process
- Ad-hoc signed; installs to `~/Applications` via `make install`
- 11 tests, 100% line coverage on app target

## Phase 2: Post-Launch

No features currently planned. The tool does one thing well and that is the goal.
