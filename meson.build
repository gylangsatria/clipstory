project('clipstory', 'vala', version: '1.5.0')

gtk = dependency('gtk+-3.0')
granite = dependency('granite')
gee = dependency('gee-0.8')
json_glib = dependency('json-glib-1.0')
libportal = dependency('libportal')
libportal_gtk3 = dependency('libportal-gtk3')

app_id = 'com.github.gylangsatria.clipstory'

executable(
    app_id,
    [
        'src/main.vala',
        'src/window.vala',
        'src/clipboard-history.vala'
    ],
    dependencies: [gtk, granite, gee, json_glib, libportal, libportal_gtk3],
    install: true
)

install_data(
    'data/com.github.gylangsatria.clipstory.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    'data/icons/hicolor/128x128/apps/com.github.gylangsatria.clipstory.png',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/128x128/apps')
)

# AppStream metainfo
install_data(
    'data/com.github.gylangsatria.clipstory.metainfo.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)