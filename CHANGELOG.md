# Changelog / Code Review

## Version 1.3.0

### New Features
- Configurable max history items via settings popover
- JSON file persistence for clipboard history
- Dark mode toggle

### Bug Fixes & Improvements
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

### Priority Summary (Remaining)

| Priority | Items                                                                       |
| -------- | --------------------------------------------------------------------------- |
| High     | —                                                                           |
| Medium   | —                                                                           |
| Low      | #17 (improvements)  |
