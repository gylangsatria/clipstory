using Gtk;
using Granite;

public class MainWindow : Gtk.ApplicationWindow {

    ClipboardHistory manager;
    
    Gtk.SearchEntry search;
    Gtk.ListBox list;
    
    // Tambahan untuk pagination
    int visible_items = 10;
    int current_offset = 0;
    Gtk.Button show_more_button;
    Gtk.Button show_less_button;
    Gtk.Box button_box;
    Gtk.Label info_label;
    
    // Dark mode
    Gtk.Switch dark_mode_switch;
    Gtk.CssProvider css_provider;
    
    // Version info
    Gtk.Label version_label;
    
    public MainWindow(Gtk.Application app, ClipboardHistory manager) {
        
        Object(application: app,
            title: "ClipStory",
            default_width: 420,
            default_height: 500);
        
        this.manager = manager;
        
        // Set role untuk identifikasi window
        this.set_role("clipstory-main");
        
        // Set icon name yang sama dengan desktop entry
        this.set_icon_name("com.github.gylangsatria.clipboard-history");
        
        // Pastikan window tidak di-skip oleh window manager
        this.set_skip_taskbar_hint(false);
        this.set_skip_pager_hint(false);

        // ====================================
        
        // Inisialisasi CSS provider untuk dark mode
        css_provider = new Gtk.CssProvider();
        var screen = Gdk.Screen.get_default();
        if (screen != null) {
            Gtk.StyleContext.add_provider_for_screen(
                screen,
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }
        
        var header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.title = "ClipStory";
        
        // Box untuk tombol di kanan header
        var header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        
        // Tombol dark mode
        var dark_mode_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        var dark_mode_label = new Gtk.Label("Dark Mode");
        dark_mode_label.get_style_context().add_class("dim-label");
        
        dark_mode_switch = new Gtk.Switch();
        dark_mode_switch.valign = Align.CENTER;
        
        // Cek preferensi sistem untuk dark mode
        var settings = Gtk.Settings.get_default();
        bool is_dark = settings.gtk_application_prefer_dark_theme;
        dark_mode_switch.active = is_dark;
        apply_dark_mode(is_dark);
        
        dark_mode_switch.notify["active"].connect(() => {
            apply_dark_mode(dark_mode_switch.active);
        });
        
        dark_mode_box.pack_start(dark_mode_label, false, false, 0);
        dark_mode_box.pack_start(dark_mode_switch, false, false, 0);
        
        // Tombol settings
        var settings_button = new Gtk.Button.from_icon_name("emblem-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        settings_button.tooltip_text = "Settings";
        settings_button.relief = ReliefStyle.NONE;
        
        var settings_popover = new Gtk.Popover(settings_button);
        settings_popover.position = PositionType.BOTTOM;
        
        var settings_grid = new Gtk.Grid();
        settings_grid.margin = 12;
        settings_grid.row_spacing = 8;
        settings_grid.column_spacing = 12;
        
        var max_items_label = new Gtk.Label("Max History Items:");
        max_items_label.xalign = 0;
        
        var max_items_spin = new Gtk.SpinButton.with_range(10, 500, 5);
        max_items_spin.value = manager.max_items;
        max_items_spin.tooltip_text = "Maximum number of clipboard items to store";
        
        max_items_spin.value_changed.connect(() => {
            manager.max_items = (int)max_items_spin.value;
        });
        
        // Autostart toggle (via xdg-desktop-portal)
        var autostart_label = new Gtk.Label("Auto Start:");
        autostart_label.xalign = 0;
        
        var autostart_switch = new Gtk.Switch();
        autostart_switch.halign = Align.START;
        autostart_switch.valign = Align.CENTER;
        autostart_switch.active = false;
        autostart_switch.tooltip_text = "Start ClipStory automatically at login";
        
        autostart_switch.notify["active"].connect(() => {
            if (autostart_switch.active) {
                request_autostart.begin((obj, res) => {
                    bool granted = request_autostart.end(res);
                    if (!granted) {
                        autostart_switch.active = false;
                    }
                });
            }
        });
        
        settings_grid.attach(max_items_label, 0, 0, 1, 1);
        settings_grid.attach(max_items_spin, 1, 0, 1, 1);
        settings_grid.attach(autostart_label, 0, 1, 1, 1);
        settings_grid.attach(autostart_switch, 1, 1, 1, 1);
        settings_popover.add(settings_grid);
        
        settings_button.clicked.connect(() => {
            settings_popover.show_all();
        });
        
        // tombol clear all
        var clear_button = new Gtk.Button.with_label("Clear");
        clear_button.tooltip_text = "Clear all history";
        
        clear_button.clicked.connect(() => {
            manager.clear_all();
            current_offset = 0;
            refresh_list();
        });
        
        header_box.pack_start(dark_mode_box, false, false, 0);
        header_box.pack_end(clear_button, false, false, 0);
        header_box.pack_end(settings_button, false, false, 0);
        
        header.set_custom_title(header_box);
        
        set_titlebar(header);
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        box.margin = 12;
        
        search = new Gtk.SearchEntry();
        search.placeholder_text = "Search clipboard history...";
        
        list = new Gtk.ListBox();
        list.selection_mode = SelectionMode.NONE;
        
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.expand = true;
        scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(list);
        
        // Buat box untuk tombol show more/less
        button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        button_box.halign = Align.CENTER;
        button_box.margin_top = 6;
        
        show_more_button = new Gtk.Button.with_label("Show More");
        show_less_button = new Gtk.Button.with_label("Show Less");
        show_less_button.sensitive = false;
        
        info_label = new Gtk.Label("");
        info_label.margin_top = 6;
        info_label.margin_bottom = 6;
        
        show_more_button.clicked.connect(() => {
            current_offset += visible_items;
            refresh_list();
        });
        
        show_less_button.clicked.connect(() => {
            if (current_offset >= visible_items) {
                current_offset -= visible_items;
            } else {
                current_offset = 0;
            }
            refresh_list();
        });
        
        button_box.pack_start(show_less_button, false, false, 0);
        button_box.pack_start(show_more_button, false, false, 0);
        
        // Version label di bagian bawah
        var version_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        version_box.halign = Align.CENTER;
        version_box.margin_top = 8;
        
        version_label = new Gtk.Label("");
        version_label.get_style_context().add_class("dim-label");
        version_label.set_markup("<small>ClipStory v1.5.0</small>");
        
        // Tambahkan link ke repository atau info
        var about_button = new Gtk.Button.with_label("ℹ️");
        about_button.tooltip_text = "About";
        about_button.relief = ReliefStyle.NONE;
        about_button.width_request = 24;
        about_button.height_request = 24;
        
        about_button.clicked.connect(() => {
            show_about_dialog();
        });
        
        version_box.pack_start(version_label, false, false, 0);
        version_box.pack_start(about_button, false, false, 0);
        
        box.pack_start(search, false, false, 0);
        box.pack_start(scroll, true, true, 0);
        box.pack_start(button_box, false, false, 0);
        box.pack_start(info_label, false, false, 0);
        box.pack_start(version_box, false, false, 0);
        
        add(box);
        
        manager.history_changed.connect(() => {
            current_offset = 0;
            refresh_list();
        });
        
        search.changed.connect(() => {
            current_offset = 0;
            refresh_list();
        });
        
        // Double-click via row_activated, bukan single-click
        list.set_activate_on_single_click(false);
        
        // Signal untuk row_activated — connect sekali di sini, bukan di refresh_list
        list.row_activated.connect(on_row_activated);
        list.button_press_event.connect(on_list_button_press);
        
        // Initial population of the list
        refresh_list();
    }
    
    // Request autostart via xdg-desktop-portal (supports Flatpak)
    async bool request_autostart() {
        var portal = new Xdp.Portal();
        
        Xdp.Parent? parent = Xdp.parent_new_gtk(this);
        
        var command = new GenericArray<weak string>();
        command.add("com.github.gylangsatria.clipboard-history");
        
        try {
            return yield portal.request_background(
                parent,
                "ClipStory will automatically start when this device turns on and run in the background so your clipboard history is always available.",
                (owned) command,
                Xdp.BackgroundFlags.AUTOSTART,
                null
            );
        } catch (Error e) {
            warning("Failed to request autostart: %s", e.message);
            return false;
        }
    }
    
    void show_about_dialog() {
        var about = new Gtk.AboutDialog();
        about.set_transient_for(this);
        about.set_program_name("ClipStory");
        about.set_version("1.5.0");
        about.set_comments("A clipboard history manager");
        about.set_copyright("© 2026 Gylang Satria");
        about.set_license_type(Gtk.License.GPL_3_0);
        about.set_website("https://github.com/gylangsatria/clipboard-history-elementaryos");
        about.set_website_label("GitHub Repository");
        about.set_authors({"Gylang Satria <sayugiteam@gmail.com>"});
        
        about.set_logo_icon_name("com.github.gylangsatria.clipboard-history");
        
        about.run();
        about.destroy();
    }
    
void apply_dark_mode(bool dark) {
    var settings = Gtk.Settings.get_default();
    settings.gtk_application_prefer_dark_theme = dark;
    
    // CSS tambahan untuk dark mode
    if (dark) {
        string css = """
            /* Dark mode styles */
            .background {
                background-color: #2d2d2d;
            }
            
            GtkListBoxRow {
                background-color: #3c3c3c;
                border-bottom: 1px solid #4a4a4a;
            }
            
            GtkListBoxRow:hover {
                background-color: #4a4a4a;
            }
            
            GtkLabel {
                color: #f0f0f0;
            }
            
            .dim-label {
                color: #a0a0a0;
            }
            
            GtkSearchEntry {
                background-color: #3c3c3c;
                color: #f0f0f0;
                border: 1px solid #4a4a4a;
            }
            
            GtkButton {
                background-color: #4a4a4a;
                color: #f0f0f0;
                border: 1px solid #5a5a5a;
            }
            
            GtkButton:hover {
                background-color: #5a5a5a;
            }
            
            .destructive-action {
                background-color: #c6262e;
                color: white;
            }
            
            .destructive-action:hover {
                background-color: #e33a42;
            }
            
            GtkScrolledWindow {
                background-color: #2d2d2d;
            }
            
            /* Style untuk about button */
            GtkButton.flat {
                background-color: transparent;
                border: none;
            }
            
            GtkButton.flat:hover {
                background-color: rgba(255, 255, 255, 0.1);
            }
        """;
        try {
            css_provider.load_from_data(css, -1);
        } catch (Error e) {
            warning("Failed to load dark theme CSS: %s", e.message);
        }
    } else {
        // Reset ke tema default
        string css = """
            /* Light mode - default theme */
            GtkListBoxRow {
                background-color: transparent;
                border-bottom: 1px solid #e0e0e0;
            }
            
            .dim-label {
                color: #6c6c6c;
            }
            
            /* Style untuk about button */
            GtkButton.flat {
                background-color: transparent;
                border: none;
            }
            
            GtkButton.flat:hover {
                background-color: rgba(0, 0, 0, 0.05);
            }
        """;
        try {
            css_provider.load_from_data(css, -1);
        } catch (Error e) {
            warning("Failed to load light theme CSS: %s", e.message);
        }
    }
}
    
    // Fungsi untuk memotong teks jika terlalu panjang
    string truncate_text(string text, int max_length = 80) {
        if (text.length <= max_length) {
            return text;
        }
        
        // Coba potong di spasi terakhir
        int last_space = text.last_index_of_char(' ', max_length - 3);
        if (last_space > 0) {
            return text.substring(0, last_space) + "...";
        } else {
            return text.substring(0, max_length - 3) + "...";
        }
    }
    
    // Fungsi untuk mendapatkan preview teks (baris pertama)
    string get_preview(string text) {
        string[] lines = text.split("\n");
        string first_line = lines[0];
        
        // Jika hanya satu baris dan pendek
        if (lines.length == 1 && first_line.length <= 80) {
            return first_line;
        }
        
        // Jika ada banyak baris — tampilkan baris pertama + indikator jumlah baris
        if (lines.length > 1) {
            string preview = truncate_text(first_line, 60);
            return @"$preview [$(lines.length) lines]";
        }
        
        // Baris pertama panjang
        return truncate_text(first_line, 80);
    }
    
    void refresh_list() {
        
        // Destroy semua child untuk mencegah memory leak
        // (remove saja tidak cukup — widget tetap di memory)
        List<weak Widget> children = list.get_children();
        foreach (Widget child in children) {
            list.remove(child);
            child.destroy();
        }
        
        var query = search.text;
        Gee.ArrayList<string> items;
        
        if (query == "") {
            items = manager.history;
        } else {
            items = manager.search(query);
        }
        
        // Dapatkan total items menggunakan method size dari Gee.ArrayList
        int total_items = items.size;
        
        // Hitung item yang akan ditampilkan
        int start_index = current_offset;
        int end_index = int.min(start_index + visible_items, total_items);
        
        // Update info label — pastikan range valid
        if (total_items > 0 && start_index < total_items) {
            info_label.label = "Showing %d-%d of %d items".printf(start_index + 1, end_index, total_items);
        } else if (total_items > 0) {
            info_label.label = "Showing 1-%d of %d items".printf(total_items, total_items);
        } else {
            info_label.label = "No items found";
        }
        
        // Tampilkan item dalam range tertentu
        for (int i = start_index; i < end_index; i++) {
            string full_text = items.@get(i);
            string preview_text = get_preview(full_text);
            
            var row = new Gtk.ListBoxRow();
            
            // Set ukuran baris yang seragam
            row.height_request = 70;
            row.margin_top = 2;
            row.margin_bottom = 2;
            
            var row_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            row_box.margin_start = 6;
            row_box.margin_end = 6;
            row_box.margin_top = 6;
            row_box.margin_bottom = 6;
            
            // Label container dengan ukuran tetap
            var label_container = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
            label_container.hexpand = true;
            label_container.height_request = 50;
            
            // Label untuk preview
            var label = new Gtk.Label(preview_text);
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            label.xalign = 0;
            label.valign = Align.CENTER;
            label.ellipsize = Pango.EllipsizeMode.END;
            label.max_width_chars = 45;
            label.lines = 2;
            label.justify = Justification.LEFT;
            label.tooltip_text = full_text; // Tooltip untuk melihat teks lengkap
            
            // Tambahkan label info jika teks memiliki banyak baris
            if (full_text.contains("\n") || full_text.length > 100) {
                var info_badge = new Gtk.Label("");
                info_badge.xalign = 0;
                info_badge.margin_top = 2;
                info_badge.get_style_context().add_class("dim-label");
                info_badge.label = "Multi-line • Hover for preview";
                info_badge.tooltip_text = full_text;
                
                label_container.pack_start(label, true, true, 0);
                label_container.pack_start(info_badge, false, false, 0);
            } else {
                label_container.pack_start(label, true, true, 0);
            }
            
            // Tombol dengan ukuran tetap
            var button_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
            button_container.halign = Align.END;

            // Pin button — pakai emoji pin agar kompatibel semua tema
            bool item_pinned = manager.is_pinned(full_text);
            var pin_button = new Gtk.Button.with_label("📌");
            pin_button.width_request = 28;
            pin_button.height_request = 28;
            pin_button.tooltip_text = item_pinned ? "Unpin" : "Pin this item";
            pin_button.relief = ReliefStyle.NONE;
            
            // Set opacity untuk visual pin/unpin
            pin_button.opacity = item_pinned ? 1.0 : 0.4;
            
            pin_button.clicked.connect(() => {
                manager.toggle_pin(full_text);
                bool now_pinned = manager.is_pinned(full_text);
                pin_button.tooltip_text = now_pinned ? "Unpin" : "Pin this item";
                pin_button.opacity = now_pinned ? 1.0 : 0.4;
            });
            
            var copy_button = new Gtk.Button.with_label("Copy");
            copy_button.width_request = 65;
            copy_button.height_request = 32;
            
            var delete_button = new Gtk.Button.with_label("Delete");
            delete_button.width_request = 65;
            delete_button.height_request = 32;
            delete_button.get_style_context().add_class("destructive-action");
            
            copy_button.clicked.connect(() => {
                // Salin teks lengkap, bukan preview
                manager.copy_again(full_text);
                
                // Beri feedback visual
                copy_button.label = "Copied!";
                GLib.Timeout.add(1000, () => {
                    copy_button.label = "Copy";
                    return false;
                });
            });
            
            delete_button.clicked.connect(() => {
                manager.remove_item(full_text);
                refresh_list();
            });
            
            button_container.pack_start(pin_button, false, false, 0);
            button_container.pack_start(copy_button, false, false, 0);
            button_container.pack_start(delete_button, false, false, 0);
            
            row_box.pack_start(label_container, true, true, 0);
            row_box.pack_start(button_container, false, false, 0);
            
            row.add(row_box);
            list.add(row);
        }
        
        // Update status tombol show more/less
        show_less_button.sensitive = (current_offset > 0);
        show_more_button.sensitive = (end_index < total_items);
        
        // Sembunyikan button box jika total items <= visible_items
        button_box.visible = (total_items > visible_items);
        
        list.show_all();
    }
    
    // Handler row_activated — dipanggil via signal (bukan lambda baru tiap refresh)
    private void on_row_activated(Gtk.ListBoxRow row) {
        int idx = row.get_index();
        int actual_idx = current_offset + idx;
        
        var q = search.text;
        Gee.ArrayList<string> all_items;
        if (q == "") {
            all_items = manager.history;
        } else {
            all_items = manager.search(q);
        }
        
        if (actual_idx >= 0 && actual_idx < all_items.size) {
            string text = all_items.@get(actual_idx);
            manager.copy_again(text);
            
            // Cari tombol Copy di row ini dan beri feedback
            var row_box_w = row.get_child() as Gtk.Box;
            if (row_box_w != null) {
                var children = row_box_w.get_children();
                if (children.length() >= 2) {
                    var btn_container = children.nth_data(1) as Gtk.Box;
                    if (btn_container != null) {
                        foreach (Widget w in btn_container.get_children()) {
                            var btn = w as Gtk.Button;
                            if (btn != null && btn.label == "Copy") {
                                btn.label = "Copied!";
                                GLib.Timeout.add(1000, () => {
                                    btn.label = "Copy";
                                    return false;
                                });
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Handler double-click — connect sekali, bukan tiap refresh
    private bool on_list_button_press(Gdk.EventButton event) {
        if (event.type == Gdk.EventType.@2BUTTON_PRESS && event.button == 1) {
            var row = list.get_row_at_y((int)event.y);
            if (row != null) {
                int actual_idx = current_offset + row.get_index();
                var q = search.text;
                Gee.ArrayList<string> all_items;
                if (q == "") {
                    all_items = manager.history;
                } else {
                    all_items = manager.search(q);
                }
                if (actual_idx >= 0 && actual_idx < all_items.size) {
                    manager.copy_again(all_items.@get(actual_idx));
                }
                return true;
            }
        }
        return false;
    }
}