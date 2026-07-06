# Changelog / Code Review

## Version 1.4.2

### Improvements
- **Double-click** on any history item to automatically copy it to clipboard (feedback "Copied!" appears on the Copy button)

---

## Version 1.4.1

### New Features
- Pin/unpin clipboard items — pinned items are protected from Clear All and auto-trim
- Pin button (📌) on each history item row
- Pinned state persists in JSON format (`{"text": "...", "pinned": true/false}`)
- Auto-migration from legacy JSON format (array of strings)
- **Double-click** on any history item to automatically copy it to clipboard

### Bug Fixes
- `clear_all()` now only removes non-pinned items
- `max_items` trim skips pinned items
- Remove pin automatically when item is deleted

## Version 1.4.0

### New Features
- Clipboard monitoring now keeps running even when window is closed (hide-on-delete)
- Re-open window by running `clipboard-history` again while app is running in background
- Debounced JSON persistence (500ms debounce — reduces disk writes)
- **Ctrl+Q** shortcut to quit application completely
- Dev script: add separate menu options for Build (meson setup), Compile (meson compile), and Install (sudo ninja install)
- Ignore generated files in `deb-package/usr/bin/`, `usr/share/`, `etc/` via `.gitignore`

### Bug Fixes
- Fix clipboard not detected from some apps (Electron, Chromium, Wayland) by adding polling fallback (400ms)
- Fix app exiting completely when window is closed (monitoring stops)
- Fix `save_history()` writing to disk on every clipboard change (now debounced with 500ms debounce timer)
- Fix redundant `#if !GTK_3_22` dead code (both branches were identical)
- Fix duplicate `show_all()` call in constructor
- Fix license mismatch (README said MIT, About dialog used GPL-3.0)
- Fix missing `libjson-glib-1.0-0` dependency in deb package control file
- Fix `Gdk.Screen.get_default()` could return `null` on Wayland (add null check in `apply_dark_mode`)
- Fix `.gitignore` trailing slash on `deb-package.deb` pattern (file, not directory)
- Fix `dev-setup.sh` uninstall missing `libjson-glib-dev`
- Fix `info_label` showing invalid range when offset exceeds total items
- Fix unreachable `try-catch` clauses on `set_icon_name()` and `set_logo_icon_name()`
- Fix tracked compiled binary `deb-package/usr/bin/clipboard-history` (removed from git tracking)
- Update README project structure to match actual files

---

## Version 1.3.0

### New Features
- Configurable max history items via settings popover
- JSON file persistence for clipboard history
- Dark mode toggle
- Auto Start toggle in settings (enable/disable startup via GUI)

### Bug Fixes & Improvements
- Fix text stripping inconsistency in `check_clipboard_async()` (use `cleaned_text` instead of `text` for history storage)
- Prevent unnecessary `owner_change` signal in `copy_again()`
- Add GTK and X-GNOME-Utilities to desktop file categories
- Improve search placeholder text
- Simplify `get_preview()` function
- Correct uninstall command in README

---

## Version 1.2.0 — Bug Report & Improvement Suggestions

### Fixes Applied

| #   | Issue                                       | Status                  | Commit                                                            |
| --- | ------------------------------------------- | ----------------------- | ----------------------------------------------------------------- |
| 1   | indicator.vala not compiled                 | Resolved (file deleted) | `chore: remove unused indicator.vala (dead code)`                 |
| 2   | ClipboardIndicator class never instantiated | Resolved (file deleted) | `chore: remove unused indicator.vala (dead code)`                 |
| 3   | refresh_list() not called on startup        | Fixed                   | `fix: call refresh_list() on startup to populate initial UI`      |
| 4   | Timeout timer never stopped                 | Fixed                   | `fix: prevent dangling timer reference in ClipboardHistory`       |
| 5   | Typo in asset filename                      | Fixed                   | `fix: correct typo in asset filename (cliboard -> clipboard)`     |
| 6   | Gtk.StatusIcon is deprecated                | Resolved (file deleted) | `chore: remove unused indicator.vala (dead code)`                 |
| 7   | Version mismatch                            | Fixed                   | `fix: sync deb package version with app version (1.2 -> 1.2.0)`   |
| 8   | No autostart configuration                  | Fixed                   | `feat: add autostart configuration for clipboard manager`         |
| 9   | Redundant clipboard polling mechanism       | Fixed                   | `fix: remove redundant clipboard polling timer`                   |
| 10  | max_items is hardcoded                      | Fixed                   | `feat: make max_items configurable via settings popover`          |
| 11  | copy_again() triggers unnecessary owner_change signal | Fixed | `fix: prevent unnecessary owner_change signal in copy_again()` |
| 12  | Incorrect uninstall instruction in README    | Fixed                   | `fix: correct uninstall command in README (meson install -> ninja uninstall)` |
| 13  | Improve .gitignore                          | Done                    | `chore: improve .gitignore with build artifacts and editor files` |
| 14  | Improve Desktop file categories             | Fixed                   | `feat: add GTK and X-GNOME-Utilities to desktop file categories` |
| 15  | Improve SearchEntry placeholder text        | Fixed                   | `fix: update placeholder text to "Search clipboard history..."` |
| 16  | Simplify get_preview function               | Fixed                   | `refactor: remove redundant lines.length == 0 check in get_preview` |
| 19  | Persist clipboard history                   | Fixed                   | `feat: add JSON file persistence for clipboard history` |
| 20  | Add max_items configuration UI              | Fixed                   | `feat: make max_items configurable via settings popover` |

### Remaining Issues

#### Suggestions for Improvement

17. **Add keyboard shortcuts**
    - No keyboard shortcuts exist (e.g., `Ctrl+F` to focus search, `Delete` to remove selected item, `Escape` to close window).

18. **Wingpanel indicator integration**
    - Add a Wingpanel indicator icon in the top panel so users can access clipboard history without opening the full window.
    - The indicator popover would show recent history items and quick actions (copy, pin, clear).
    - Requires a separate Wingpanel plugin (shared library).

### Priority Summary (Remaining)

| Priority | Items                                                                       |
| -------- | --------------------------------------------------------------------------- |
| High     | —                                                                           |
| Medium   | #18 (Wingpanel indicator)                                                   |
| Low      | #17 (keyboard shortcuts)  |
