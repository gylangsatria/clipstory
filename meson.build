project('clipboard-history', 'vala', version: '1.4.5')

gtk = dependency('gtk+-3.0')
granite = dependency('granite')
gee = dependency('gee-0.8')
json_glib = dependency('json-glib-1.0')

app_id = 'com.github.gylangsatria.clipboard-history'

executable(
    app_id,
    [
        'src/main.vala',
        'src/window.vala',
        'src/clipboard-history.vala'
    ],
    dependencies: [gtk, granite, gee, json_glib],
    install: true
)

install_data(
    'data/com.github.gylangsatria.clipboard-history.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    'data/icons/hicolor/128x128/apps/com.github.gylangsatria.clipboard-history.png',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/128x128/apps')
)

install_data(
    'data/com.github.gylangsatria.clipboard-history-autostart.desktop',
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
)

# AppStream metainfo
install_data(
    'data/com.github.gylangsatria.clipboard-history.metainfo.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)