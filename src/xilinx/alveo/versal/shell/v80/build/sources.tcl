# Post-load source file configuration:
#
# 1. Header files (.svh, .vh): Vivado defaults these to used_in_synthesis=false
#    when added via add_file. Force them true BEFORE update_compile_order so
#    the synthesis engine can resolve `include directives when validating TOP.
#    Without this, Vivado fails TOP validation, auto-selects a wrong module,
#    and the subsequent compile-order query returns a garbage reachable set.
#
# 2. Top module: re-assert after enabling headers, because Vivado may have
#    already auto-selected a replacement top during initial project load.
#
# 3. Source files (.sv, .v): Vivado elaborates all loaded files even if
#    unreachable from TOP. Use update_compile_order to find the reachable set
#    and mark everything else used_in_synthesis=false to prevent elaboration
#    errors in unused modules. File extension is used rather than FILE_TYPE
#    to be robust across Vivado versions.

foreach f [get_files -quiet -of_objects [get_filesets sources_1]] {
    set ext [file extension $f]
    if {$ext eq ".svh" || $ext eq ".vh"} {
        set_property used_in_synthesis true $f
    }
}

set_property top esnet_smartnic [get_filesets sources_1]
update_compile_order -fileset sources_1
set in_order [get_files -compile_order sources -used_in synthesis]

foreach f [get_files -quiet -of_objects [get_filesets sources_1]] {
    set ext [file extension $f]
    if {$ext eq ".sv" || $ext eq ".v"} {
        if {[lsearch -exact $in_order $f] < 0} {
            set_property used_in_synthesis false $f
        }
    }
}
