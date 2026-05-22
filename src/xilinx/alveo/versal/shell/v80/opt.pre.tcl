# Clear IS_LOC_FIXED on NOC NMU/NSU cells that were fixed at CIPS-die
# Reserved sites (NOC_NMU128_X0Y20/21/23) by OOC synthesis.
# Runs inside launch_runs impl_1 before opt_design, where the project-mode
# context allows the NOC router to re-derive correct full-device placements.
#
# Filter by LOC site prefix (NOC_) rather than REF_NAME to be robust across
# Versal primitive naming variants (NOC_NMU128, NOC_NSU128, etc.).
puts "opt.pre: clearing fixed NOC NMU/NSU placements at Reserved sites..."
set _cleared 0
foreach _cell [get_cells -quiet -hierarchical -filter {IS_LOC_FIXED == 1}] {
    set _loc [get_property LOC $_cell]
    if {[regexp {^NOC_} $_loc]} {
        puts "  [get_property REF_NAME $_cell] $_cell @ $_loc"
        set_property IS_LOC_FIXED 0 $_cell
        reset_property LOC $_cell
        incr _cleared
    }
}
puts "opt.pre: cleared $_cleared fixed NOC placements."

if {[llength [get_bd_designs -quiet]] > 0} {
    puts "opt.pre: validating BD design..."
    validate_bd_design -quiet
}
