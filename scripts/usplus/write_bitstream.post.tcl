set _ltx [file join $::NP_OUT_DIR ${::NP_TOP}.ltx]
set _raw_ltx [file join $::NP_OUT_DIR ${::NP_TOP}.raw.ltx]

# Preserve hierarchical debug labels alongside the firmware-facing probe names.
file rename -force $_ltx $_raw_ltx
exec python3 [file join [file dirname [info script]] rename_pcie_reset_probes.py] \
    $_raw_ltx $_ltx
