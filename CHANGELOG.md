# Changelog / Code Review

## Version 1.2.0 — Bug Report & Improvement Suggestions

### Bug & Critical Issues

1. **indicator.vala not compiled**
   - `src/indicator.vala` exists but is not included in `meson.build`. Only `main.vala`, `window.vala`, and `clipboard-history.vala` are listed.

2. **ClipboardIndicator class never instantiated**
   - `ClipboardIndicator` is defined in `src/indicator.vala` but never instantiated in `main.vala` or anywhere else (dead code).

3. **refresh_list() not called on startup**
   - The list UI is only updated when the `history_changed()` signal fires. No initial `refresh_list()` call in the `MainWindow` constructor, so the UI remains empty until the user copies something.

4. **Timeout timer never stopped**
   - In `src/clipboard-history.vala`, `Timeout.add(1000)` creates a repeating timer without storing its source ID. If the `ClipboardHistory` object is destroyed, the timer continues running with a dangling reference.

5. **Typo in asset filename**
   - `assets/cliboard-history-full.png` is missing the letter 'p' (should be `clipboard-history-full.png`).

### Medium Severity Issues

6. **Gtk.StatusIcon is deprecated**
   - `src/indicator.vala` uses `Gtk.StatusIcon`, which has been deprecated since GTK 3.14. Prefer `Gio.Application` with notifications or `Gtk.ApplicationWindow` instead.

7. **Version mismatch**
   - `deb-package/DEBIAN/control` lists `Version: 1.2`, but the About dialog in `window.vala` shows `v1.2.0`.

8. **No autostart configuration**
   - The application lacks a `.desktop` file in `~/.config/autostart/`, which is expected for a clipboard manager that should run automatically at login.

9. **Redundant clipboard polling mechanism**
   - Two mechanisms detect clipboard changes: the `owner_change` signal and a `Timeout.add(1000)` polling timer. One should suffice (preferably the signal), since `request_text` is already asynchronous.

10. **max_items is hardcoded**
    - `max_items = 50` is hardcoded in `ClipboardHistory`. It should be configurable by the user via GUI or a configuration file.

11. **copy_again() triggers unnecessary owner_change signal**
    - `clipboard.set_text()` followed by `clipboard.store()` in `copy_again()` fires the `owner_change` signal, which calls `check_clipboard_async()` again. Although protected by the `last_text` check, this is an unnecessary operation.

12. **Incorrect uninstall instruction in README**
    - The README states `sudo meson install -C build` for uninstall, but that is the **install** command. The correct uninstall command is `sudo ninja -C build uninstall`.

### Suggestions for Improvement

13. **Add .gitignore**
    - No `.gitignore` file exists. Add one to exclude `build/`, `*-stamp`, `.o` files, and compiled binaries from version control.

14. **Improve Desktop file categories**
    - `data/clipboard-history.desktop` only has `Categories=Utility;`. Add `GTK` and `X-GNOME-Utilities` for better desktop environment integration.

15. **Improve SearchEntry placeholder text**
    - Change the placeholder from "Search clipboard" to something more descriptive like "Search clipboard history...".

16. **Simplify get_preview function**
    - In `window.vala`, `get_preview()` splits on `\n` and then checks `lines.length == 0`, but the split result can never be empty (at least one element). This check is redundant.

17. **Remove dead code or properly implement indicator**
    - Either delete `indicator.vala` since it is unused, or integrate it into `main.vala` using a modern tray icon mechanism.

18. **Add keyboard shortcuts**
    - No keyboard shortcuts exist (e.g., `Ctrl+F` to focus search, `Delete` to remove selected item, `Escape` to close window).

19. **Persist clipboard history**
    - Clipboard history is lost when the application closes. Add storage to a file (JSON/CSV/DB) to retain history between sessions.

20. **Add max_items configuration UI**
    - Add preferences/settings so users can configure the maximum number of history items through the GUI.

### Priority Summary

| Priority | Items |
|---------|-------|
| High | #1 (indicator.vala not compiled), #3 (refresh_list startup), #4 (timer leak) |
| Medium | #6 (StatusIcon deprecated), #7 (version mismatch), #8 (autostart), #9 (redundant polling), #12 (README uninstall), #13 (.gitignore) |
| Low | #5 (typo in asset), #10 (max_items hardcoded), #11 (extra owner_change), #14-20 (improvements) |
