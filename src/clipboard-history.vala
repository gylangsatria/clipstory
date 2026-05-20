using Gtk;
using Gee;

public class ClipboardHistory : Object {

    public ArrayList<string> history = new ArrayList<string>();
    private Clipboard clipboard;
    private string last_text = "";
    private int _max_items = 50;
    private string data_file;

    public int max_items {
        get { return _max_items; }
        set {
            _max_items = value;
            // Trim history jika melebihi batas baru
            while (history.size > _max_items) {
                history.remove_at(history.size - 1);
            }
            history_changed();
        }
    }

    public signal void history_changed();

    public ClipboardHistory () {

        clipboard = Clipboard.get(Gdk.SELECTION_CLIPBOARD);

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

        // Simpan history setiap ada perubahan
        this.history_changed.connect(() => {
            save_history();
        });
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

            // limit history
            if (history.size > max_items) {
                history.remove_at(history.size - 1);
            }

            history_changed();
        });
    }

    public void copy_again(string text) {
        // Set last_text sebelum mengubah clipboard agar signal owner_change
        // yang dipicu oleh set_text/store tidak memproses ulang teks yang sama
        last_text = text;
        clipboard.set_text(text, -1);
        clipboard.store(); 
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

        history.remove(text);
        history_changed();
    }

    // hapus semua history
    public void clear_all() {

        history.clear();
        history_changed();
    }

    // Simpan history ke file JSON
    private void save_history() {
        try {
            var builder = new Json.Builder();
            builder.begin_array();
            foreach (var item in history) {
                builder.add_string_value(item);
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
                var item = arr.get_string_element(i);
                if (item != null) {
                    history.add(item);
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