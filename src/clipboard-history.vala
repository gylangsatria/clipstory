using Gtk;
using Gee;

public class ClipboardHistory : Object {

    public ArrayList<string> history = new ArrayList<string>();
    private HashSet<string> pinned = new HashSet<string>();
    private Clipboard clipboard;
    private string last_text = "";
    private int _max_items = 50;
    private string data_file;

    public int max_items {
        get { return _max_items; }
        set {
            _max_items = value;
            trim_history();
            history_changed();
        }
    }

    public signal void history_changed();

    private uint poll_timer_id = 0;
    private uint save_debounce_id = 0;

    public ClipboardHistory () {

        clipboard = Clipboard.get(Gdk.SELECTION_CLIPBOARD);

        // Signal owner_change — tidak selalu reliabel (terutama Wayland & Electron)
        clipboard.owner_change.connect(() => {
            check_clipboard_async();
        });

        // Setup data file path
        string data_dir = Path.build_filename(
            Environment.get_user_data_dir(), "clipboard-history"
        );
        data_file = Path.build_filename(data_dir, "history.json");

        // Buat direktori jika belum ada
        DirUtils.create_with_parents(data_dir, 0755);

        // Muat history dari file
        load_history();

        // Simpan history — pakai debounce supaya tidak nulis file tiap 400ms
        this.history_changed.connect(() => {
            if (save_debounce_id > 0) {
                GLib.Source.remove(save_debounce_id);
            }
            save_debounce_id = GLib.Timeout.add(500, () => {
                save_history();
                save_debounce_id = 0;
                return false;
            });
        });

        // Polling fallback: cek clipboard tiap 400ms
        // Banyak aplikasi tidak memicu owner_change, jadi polling diperlukan
        poll_timer_id = GLib.Timeout.add(400, () => {
            check_clipboard_async();
            return GLib.Source.CONTINUE;
        });
    }

    ~ClipboardHistory() {
        if (poll_timer_id > 0) {
            GLib.Source.remove(poll_timer_id);
            poll_timer_id = 0;
        }
        if (save_debounce_id > 0) {
            GLib.Source.remove(save_debounce_id);
            save_debounce_id = 0;
        }
    }

    void check_clipboard_async() {

        clipboard.request_text((clipboard, text) => {

            if (text == null)
                return;

            var cleaned_text = text.strip();

            if (cleaned_text == "" || cleaned_text == last_text)
                return;

            last_text = cleaned_text;

            // hindari duplikat
            history.remove(cleaned_text);
            history.insert(0, cleaned_text);

            trim_history();

            history_changed();
        });
    }

    // Hapus item non-pinned paling tua jika melebihi batas
    private void trim_history() {
        while (history.size > _max_items) {
            // Cari dari belakang — jangan hapus item yang di-pin
            bool removed = false;
            for (int i = history.size - 1; i >= 0; i--) {
                if (!pinned.contains(history.@get(i))) {
                    history.remove_at(i);
                    removed = true;
                    break;
                }
            }
            if (!removed) break; // Semua item di-pin, stop
        }
    }

    public void copy_again(string text) {
        // Set last_text sebelum mengubah clipboard agar signal owner_change
        // yang dipicu oleh set_text/store tidak memproses ulang teks yang sama
        last_text = text;
        clipboard.set_text(text, -1);
        clipboard.store(); 
    }

    // Pin / unpin item
    public bool is_pinned(string text) {
        return pinned.contains(text);
    }

    public void toggle_pin(string text) {
        if (pinned.contains(text)) {
            pinned.remove(text);
        } else {
            pinned.add(text);
        }
        history_changed();
    }

    public ArrayList<string> search(string query) {

        var results = new ArrayList<string>();
        var q = query.down();

        foreach (var item in history) {
            if (item.down().contains(q)) {
                results.add(item);
            }
        }

        return results;
    }

    // hapus item tertentu
    public void remove_item(string text) {
        pinned.remove(text); // Lepas pin juga
        history.remove(text);
        history_changed();
    }

    // hapus semua history (kecuali yang di-pin)
    public void clear_all() {
        var to_remove = new ArrayList<string>();
        foreach (var item in history) {
            if (!pinned.contains(item)) {
                to_remove.add(item);
            }
        }
        foreach (var item in to_remove) {
            history.remove(item);
        }
        history_changed();
    }

    // Simpan history ke file JSON
    private void save_history() {
        try {
            var builder = new Json.Builder();
            builder.begin_array();
            foreach (var item in history) {
                builder.begin_object();
                    builder.set_member_name("text");
                    builder.add_string_value(item);
                    builder.set_member_name("pinned");
                    builder.add_boolean_value(pinned.contains(item));
                builder.end_object();
            }
            builder.end_array();

            var generator = new Json.Generator();
            generator.set_root(builder.get_root());
            generator.to_file(data_file);
        } catch (Error e) {
            warning("Failed to save clipboard history: %s", e.message);
        }
    }

    // Muat history dari file JSON
    private void load_history() {
        try {
            var parser = new Json.Parser();
            parser.load_from_file(data_file);

            var root = parser.get_root();
            if (root == null || root.get_node_type() != Json.NodeType.ARRAY)
                return;

            var arr = root.get_array();
            for (int i = 0; i < arr.get_length(); i++) {
                var node = arr.get_element(i);
                if (node.get_node_type() == Json.NodeType.OBJECT) {
                    // Format baru: {"text": "...", "pinned": true/false}
                    var obj = node.get_object();
                    var text = obj.get_string_member("text");
                    if (text != null) {
                        history.add(text);
                        if (obj.get_boolean_member("pinned")) {
                            pinned.add(text);
                        }
                    }
                } else {
                    // Format lama (array of strings) — migrasi otomatis
                    var item = arr.get_string_element(i);
                    if (item != null) {
                        history.add(item);
                    }
                }
            }
        } catch (Error e) {
            // File belum ada — bukan error
            if (!(e is FileError.NOENT)) {
                warning("Failed to load clipboard history: %s", e.message);
            }
        }
    }
}