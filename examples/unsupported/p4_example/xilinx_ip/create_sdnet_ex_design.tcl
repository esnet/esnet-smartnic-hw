set PROJ_FILE ${PROJ_DIR}/${PROJ_NAME}.xpr

if { [file exists $PROJ_FILE ] } {
    open_project $PROJ_FILE

    # Generate SDnet example design files (including DPI-C driver library)
    generate_target {example} [get_ips sdnet_0]

    set_property IS_ENABLED false [get_files ./sdnet_0/example_sdnet_0.xdc]

    close_project
}
