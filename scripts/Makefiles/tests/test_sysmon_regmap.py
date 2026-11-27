"""Check the generated SYSMON API used by the firmware driver."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[3]
REGIO = REPO / "esnet-fpga-library/tools/regio"


class SysmonRegmapTest(unittest.TestCase):
    def test_generated_c_register_layout_and_sequencer_fields(self):
        with tempfile.TemporaryDirectory(prefix="sysmon-regmap-") as tmp:
            root = Path(tmp)
            env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")

            def run(*cmd):
                result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

            ir = root / "sysmon-ir.yaml"
            run(sys.executable, "-B", str(REGIO / "regio-elaborate"), "-i", str(REPO),
                "-f", "block", "-o", str(ir), str(REPO / "src/xilinx/sysmon/regio/sysmon.yaml"))
            run(sys.executable, "-B", str(REGIO / "regio-generate"), "-f", "block", "-g", "c",
                "-o", str(root), str(ir))
            source = root / "check.c"
            source.write_text('''
#include <stddef.h>
#include "sysmon_block.h"
#define OFFSET(reg, value) _Static_assert(offsetof(struct sysmon_block, reg) == value, #reg)
OFFSET(ip_interrupt_enable, 0x68);
OFFSET(temperature, 0x400);
OFFSET(vcc_psintlp, 0x434);
OFFSET(vcc_psintfp, 0x438);
OFFSET(vcc_psaux, 0x43c);
OFFSET(vaux, 0x440);
OFFSET(max_temperature, 0x480);
OFFSET(max_vccbram, 0x48c);
OFFSET(min_temperature, 0x490);
OFFSET(config_reg_1, 0x504);
OFFSET(seqchsel0, 0x518);
OFFSET(seqavg0, 0x51c);
OFFSET(seqchsel1, 0x520);
OFFSET(seqchsel2, 0x524);
OFFSET(seqavg1, 0x528);
OFFSET(seqavg2, 0x52c);
OFFSET(seqinmode0, 0x530);
OFFSET(seqinmode1, 0x534);
OFFSET(vuser0, 0x600);
OFFSET(max_vuser0, 0x680);
OFFSET(min_vuser0, 0x6a0);
OFFSET(min_vuser3, 0x6ac);
_Static_assert(sizeof(((struct sysmon_block *)0)->vaux) == 16 * 4, "VAUX array");
int main(void) {
    union sysmon_config_reg_1 config = {._v = 0};
    config.seq = SYSMON_CONFIG_REG_1_SEQ_CONTINUOUS;
    if (config._v != 0x2000) return 1;
    config.seq = SYSMON_CONFIG_REG_1_SEQ_SINGLE_CHANNEL;
    if (config._v != 0x3000) return 2;
    union sysmon_seqchsel1 channels = {._v = 0};
    channels.temperature = 1;
    channels.vcc_psintlp = 1;
    if (channels._v != 0x120) return 3;
    union sysmon_temperature temperature = {._v = 0};
    temperature.adc = 1;
    return temperature._v != 0x40;
}
''')
            run("cc", "-std=gnu11", "-Wall", "-Wextra", "-Werror", "-I" + str(root),
                str(source), "-o", str(root / "check"))
            run(str(root / "check"))


if __name__ == "__main__":
    unittest.main()
