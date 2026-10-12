using Gtk;

public class ClipboardApp : Gtk.Application {

    ClipboardHistory manager;
    MainWindow? window = null;

    // Mode headless: jalan di background tanpa menampilkan window (untuk autostart)
    bool headless = false;

    public ClipboardApp() {
        Object(application_id: "com.github.gylangsatria.clipstory",
               flags: ApplicationFlags.HANDLES_COMMAND_LINE);
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

        // Tahan proses tetap hidup walau tidak ada window terlihat,
        // supaya clipboard monitoring jalan terus di background (autostart/headless)
        this.hold();
    }

    protected override void activate() {

        if (window == null) {
            manager = new ClipboardHistory();
            window = new MainWindow(this, manager);

            // Saat user klik X, sembunyikan window, jangan di-destroy
            // Biar clipboard monitoring tetap jalan di background
            window.delete_event.connect(() => {
                window.hide_on_delete();
                return true;
            });
        }

        // Di mode headless (autostart) jangan tampilkan window — cukup monitoring.
        // Launch manual dari menu tetap menampilkan window (single-instance re-show).
        if (!headless) {
            window.show_all();
            window.present();
        }
        headless = false;
    }

    public override int command_line(ApplicationCommandLine command_line) {
        OptionEntry[] options = {
            {"headless", 'h', 0, OptionArg.NONE, ref headless,
             "Mulai tanpa menampilkan window", null},
        };

        // OptionContext.parse menghapus string dari array, jadi pakai salinan
        string[] args = command_line.get_arguments();
        string[] _args = new string[args.length];
        for (int i = 0; i < args.length; i++) {
            _args[i] = args[i];
        }

        try {
            var ctx = new OptionContext();
            ctx.set_help_enabled(true);
            ctx.add_main_entries(options, null);
            unowned string[] tmp = _args;
            ctx.parse(ref tmp);
        } catch (OptionError e) {
            command_line.printerr("error: %s\n", e.message);
            return 1;
        }

        activate();
        return 0;
    }

    public static int main(string[] args) {
        return new ClipboardApp().run(args);
    }
}