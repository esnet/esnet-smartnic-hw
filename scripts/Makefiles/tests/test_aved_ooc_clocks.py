"""Check that AVED OOC clock filtering retains constraints and fails on uncertain ownership."""
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[3]
HOOK = REPO / 'src/xilinx/alveo/versal/bd/xilinx_aved.synth.setup.tcl'
CLOCKS = [(f'sys_clk0_{n}_clk_p', 5) for n in (0, 1)] + [
    ('hbm_ref_clk_0_clk_p', 5), ('hbm_ref_clk_1_clk_p', 5),
    ('gt_pcie_refclk_clk_p', 10), ('gt_pcie0_refclk_clk_p', 10)]


class AvedOocClockTests(unittest.TestCase):
    def run_hook(self, damage=None):
        temporary = tempfile.TemporaryDirectory(prefix='aved clock hook ')
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        generated = root / 'generated'
        generated.mkdir()
        original = '# Generated OOC clocks\n' + ''.join(
            f'create_clock -name {name} -period {period} [get_ports {name}]\n' for name, period in CLOCKS)
        # Preserve unrelated constraints even if future Vivado versions add more.
        original += 'set_input_jitter [get_clocks gt_pcie_refclk_clk_p] 0.050\n'
        if damage == 'missing_clock':
            original = original.replace('create_clock -name sys_clk0_1_clk_p -period 5 [get_ports sys_clk0_1_clk_p]\n', '')
        elif damage == 'duplicate_clock':
            original += 'create_clock -name sys_clk0_0_clk_p -period 5 [get_ports sys_clk0_0_clk_p]\n'
        elif damage == 'unexpected_definition':
            original += 'create_clock -period 5 [get_ports {sys_clk0_0_clk_p}]\n'
        elif damage == 'wrong_port':
            original = original.replace('-period 5 [get_ports sys_clk0_0_clk_p]', '-period 5 [get_ports sys_clk0_1_clk_p]')
        (generated / 'xilinx_aved_ooc.xdc').write_text(original)
        for bank in (0, 1):
            ip = generated / f'xilinx_aved_axi_noc_mc_ddr4_{bank}_0/bd_0/ip/ip_0/hdl/par/input_ip.xdc'
            ip.parent.mkdir(parents=True)
            ip.write_text('create_clock -period 5.0 [get_ports sys_clk_p]\nset_property IOSTANDARD LVDS15 [get_ports sys_clk_p]\n')
            if bank == 1:
                if damage == 'missing_ip':
                    ip.unlink()
                elif damage == 'wrong_period':
                    ip.write_text(ip.read_text().replace('-period 5.0', '-period 10.0'))
                elif damage == 'missing_ip_clock':
                    ip.write_text('# No clock\n')
        before = {p: p.read_bytes() for p in generated.rglob('*.xdc')}
        driver = root / 'driver.tcl'
        driver.write_text('''
set registered 0
set auto_synthesis 1
set scope_ref {}
set scope_cells {}
set filtered_order NORMAL
proc get_files {args} {
 set pattern [lindex $args end]
 if {[string match *filtered.xdc $pattern]} {
  if {$::registered} {return [list $pattern]}; return {}
 }
 return [glob -nocomplain $pattern]
}
proc get_property {name object} {
 if {$name eq "PROCESSING_ORDER"} {
  if {[string match *filtered.xdc [lindex $object 0]]} {return $::filtered_order}; return LATE
 }
 if {$name eq "SCOPED_TO_REF"} {
  if {[string match *filtered.xdc [lindex $object 0]]} {return $::scope_ref}; return xilinx_aved
 }
 if {$name eq "SCOPED_TO_CELLS"} {return $::scope_cells}
 if {$name eq "USED_IN_SYNTHESIS" && [file tail $object] eq "xilinx_aved_ooc.xdc"} {return $::auto_synthesis}
 if {$name in {IS_ENABLED USED_IN_SYNTHESIS}} {
  if {"@DAMAGE@" eq "disabled_ip" && [string match *ddr4_1_0* $object]} {return 0}
  return 1
 }
 error "Unexpected property $name"
}
proc set_property {name value object} {
 if {$name eq "USED_IN_SYNTHESIS" && "@DAMAGE@" ne "rejected_disable"} {set ::auto_synthesis 0}
 if {$name eq "SCOPED_TO_REF"} {set ::scope_ref $value}
 if {$name eq "SCOPED_TO_CELLS"} {set ::scope_cells $value}
 if {$name eq "PROCESSING_ORDER"} {set ::filtered_order $value}
 puts "SET $name=$value $object"
}
proc read_xdc {args} {set ::registered 1; puts "READ $args"}
source {@HOOK@}
file mtime xilinx_aved_ooc.filtered.xdc 1234567890
source {@HOOK@}
puts "MTIME [file mtime xilinx_aved_ooc.filtered.xdc]"
'''.replace('@HOOK@', str(HOOK)).replace('@DAMAGE@', damage or ''))
        result = subprocess.run(['tclsh', str(driver)], cwd=root, text=True, capture_output=True)
        self.assertEqual(before, {p: p.read_bytes() for p in generated.rglob('*.xdc')})
        return result, root, original

    def test_only_the_two_duplicate_ddr_clocks_are_omitted(self):
        result, root, original = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        expected = '\n'.join(line for line in original.split('\n')
                             if not line.startswith('create_clock -name sys_clk0_'))
        self.assertEqual((root / 'xilinx_aved_ooc.filtered.xdc').read_text(), expected)
        self.assertIn('READ -mode out_of_context', result.stdout)
        self.assertIn('SET USED_IN_SYNTHESIS=false generated/xilinx_aved_ooc.xdc', result.stdout)
        self.assertIn('SET PROCESSING_ORDER=LATE', result.stdout)
        self.assertIn('SET SCOPED_TO_REF=xilinx_aved', result.stdout)
        self.assertEqual(result.stdout.count('READ -mode'), 1)
        self.assertEqual(result.stdout.count('SET USED_IN_SYNTHESIS='), 1)
        self.assertIn('MTIME 1234567890', result.stdout)
        # The DDR IP constraint files themselves must never be disabled.
        for line in result.stdout.splitlines():
            if line.startswith('SET USED_IN_SYNTHESIS='):
                self.assertNotIn('ddr4_', line)

    def test_rejected_file_property_change_stops_before_reading_replacement(self):
        result, _, _ = self.run_hook('rejected_disable')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Could not disable the generated BD OOC clocks', result.stderr)
        self.assertNotIn('READ ', result.stdout)

    def test_missing_changed_or_disabled_clock_constraints_fail_before_replacement(self):
        for damage in ('missing_clock', 'duplicate_clock', 'unexpected_definition', 'wrong_port', 'missing_ip',
                       'wrong_period', 'missing_ip_clock', 'disabled_ip'):
            with self.subTest(damage=damage):
                result, root, _ = self.run_hook(damage)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('SET USED_IN_SYNTHESIS', result.stdout)
                self.assertNotIn('READ ', result.stdout)
                self.assertFalse((root / 'xilinx_aved_ooc.filtered.xdc').exists())


if __name__ == '__main__':
    unittest.main()
