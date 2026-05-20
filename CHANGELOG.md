# Changelog / Code Review

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

### Remaining Issues

#### Medium Severity Issues

11. **copy_again() triggers unnecessary owner_change signal**
    - `clipboard.set_text()` followed by `clipboard.store()` in `copy_again()` fires the `owner_change` signal, which calls `check_clipboard_async()` again. Although protected by the `last_text` check, this is an unnecessary operation.

#### Suggestions for Improvement

14. **Improve Desktop file categories**
    - `data/clipboard-history.desktop` only has `Categories=Utility;`. Add `GTK` and `X-GNOME-Utilities` for better desktop environment integration.

15. **Improve SearchEntry placeholder text**
    - Change the placeholder from "Search clipboard" to something more descriptive like "Search clipboard history...".

16. **Simplify get_preview function**
    - In `window.vala`, `get_preview()` splits on `\n` and then checks `lines.length == 0`, but the split result can never be empty (at least one element). This check is redundant.

17. **Add keyboard shortcuts**
    - No keyboard shortcuts exist (e.g., `Ctrl+F` to focus search, `Delete` to remove selected item, `Escape` to close window).

19. **Persist clipboard history**
    - Clipboard history is lost when the application closes. Add storage to a file (JSON/CSV/DB) to retain history between sessions.

20. **Add max_items configuration UI**
    - Add preferences/settings so users can configure the maximum number of history items through the GUI.

### Priority Summary (Remaining)

| Priority | Items                                                                       |
| -------- | --------------------------------------------------------------------------- |
| High     | —                                                                           |
| Medium   | —                                                                           |
| Low      | #11 (extra owner_change), #14-20 (improvements)  |
