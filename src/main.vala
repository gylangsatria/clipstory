using Gtk;

public class ClipboardApp : Gtk.Application {

    ClipboardHistory manager;
    MainWindow? window = null;

    public ClipboardApp() {
        Object(application_id: "com.example.clipboardhistory");
    }

    protected override void startup() {
        base.startup();

        // Action quit dengan shortcut Ctrl+Q
        var quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(() => {
            this.quit();
        });
        this.add_action(quit_action);
        this.set_accels_for_action("app.quit", {"<Control>q"});
    }

    protected override void activate() {

        if (window != null) {
            // Window sudah ada — tinggal tampilkan lagi
            window.present();
            return;
        }

        manager = new ClipboardHistory();
        window = new MainWindow(this, manager);

        // Saat user klik X, sembunyikan window, jangan di-destroy
        // Biar clipboard monitoring tetap jalan di background
        window.delete_event.connect(() => {
            window.hide_on_delete();
            return true;
        });

        window.show_all();
    }

    public static int main(string[] args) {
        return new ClipboardApp().run(args);
    }
}