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
            title: "Clipboard History",
            default_width: 420,
            default_height: 500);
        
        this.manager = manager;
        
        // Cara modern untuk GTK 3.22+ - gunakan set_role dan set_wmclass (masih diperlukan)
        #if !GTK_3_22
            this.set_wmclass("clipboard-history", "ClipboardHistory");
        #else
            // Untuk GTK 3.22+, set_wmclass masih berfungsi meskipun deprecated
            this.set_wmclass("clipboard-history", "ClipboardHistory");
        #endif
        
        // Set role untuk identifikasi
        this.set_role("clipboard-history-main");
        
        // Set icon name yang sama dengan desktop entry
        try {
            this.set_icon_name("clipboard-history");
        } catch (Error e) {
            warning("Failed to set icon: %s", e.message);
        }
        
        // Pastikan window tidak di-skip oleh window manager
        this.set_skip_taskbar_hint(false);
        this.set_skip_pager_hint(false);

        // ====================================
        
        // Inisialisasi CSS provider untuk dark mode
        css_provider = new Gtk.CssProvider();
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        
        var header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.title = "Clipboard History";
        
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
        
        header.set_custom_title(header_box);
        
        set_titlebar(header);
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
        box.margin = 12;
        
        search = new Gtk.SearchEntry();
        search.placeholder_text = "Search clipboard";
        
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
        version_label.set_markup("<small>Clipboard History v1.2.0</small>");
        
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
        
        // Initial population of the list
        refresh_list();
        
        this.show_all();
        
        // Pastikan window mendapatkan fokus saat dibuka
        this.present();
    }
    
    void show_about_dialog() {
        var about = new Gtk.AboutDialog();
        about.set_transient_for(this);
        about.set_program_name("Clipboard History");
        about.set_version("1.2.0");
        about.set_comments("Clipboard history for elementary OS");
        about.set_copyright("© 2026 Gylang Satria");
        about.set_license_type(Gtk.License.GPL_3_0);
        about.set_website("https://github.com/gylangsatria/clipboard-history-elementaryos");
        about.set_website_label("GitHub Repository");
        about.set_authors({"Gylang Satria <sayugiteam@gmail.com>"});
        
        try {
            about.set_logo_icon_name("clipboard-history");
        } catch (Error e) {
            warning("Failed to set about dialog logo: %s", e.message);
        }
        
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
        // Pisahkan berdasarkan newline
        string[] lines = text.split("\n");
        
        if (lines.length == 0) {
            return "";
        }
        
        string first_line = lines[0];
        
        // Jika hanya satu baris dan pendek
        if (lines.length == 1 && first_line.length <= 80) {
            return first_line;
        }
        
        // Jika ada banyak baris atau baris pertama panjang
        if (lines.length > 1) {
            // Tampilkan baris pertama + indikator jumlah baris
            string preview = truncate_text(first_line, 60);
            return @"$preview [$(lines.length) lines]";
        } else {
            // Baris pertama panjang
            return truncate_text(first_line, 80);
        }
    }
    
    void refresh_list() {
        
        foreach (Widget child in list.get_children()) {
            list.remove(child);
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
        
        // Update info label
        if (total_items > 0) {
            info_label.label = "Showing %d-%d of %d items".printf(start_index + 1, end_index, total_items);
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
            var button_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            button_container.halign = Align.END;
            
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
}