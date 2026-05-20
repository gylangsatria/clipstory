using Gtk;
using Gee;

public class ClipboardHistory : Object {

    public ArrayList<string> history = new ArrayList<string>();
    private Clipboard clipboard;
    private string last_text = "";
    private int max_items = 50;

    public signal void history_changed();

    public ClipboardHistory () {

        clipboard = Clipboard.get(Gdk.SELECTION_CLIPBOARD);

        clipboard.owner_change.connect(() => {
            check_clipboard_async();
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
            history.remove(text);
            history.insert(0, text);

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
}