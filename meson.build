project('clipboard-history', 'vala')

gtk = dependency('gtk+-3.0')
granite = dependency('granite')
gee = dependency('gee-0.8')

executable(
    'clipboard-history',
    [
        'src/main.vala',
        'src/window.vala',
        'src/clipboard-history.vala'
    ],
    dependencies: [gtk, granite, gee],
    install: true
)

install_data(
    'data/clipboard-history.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    'data/icons/hicolor/128x128/apps/clipboard-history.png',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/128x128/apps')
)

install_data(
    'data/clipboard-history-autostart.desktop',
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
)