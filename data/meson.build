app_schema_file = files('com.github.gylangsatria.clipstory.gschema.xml')

install_data(
    app_schema_file,
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

gnome.compile_schemas(depend_files: app_schema_file)
