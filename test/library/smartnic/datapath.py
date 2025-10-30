__all__ = ()

import time
import math

from robot.api.deco import keyword, library

from smartnic.config  import *
from smartnic.packets import *
from smartnic.probes  import *

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def pkt_playback_capture_test(self, dev, num, size, port, enable_probes=True):
        pkt_playback_capture_test(dev, num, size, port, enable_probes)

    @keyword
    def pkt_accelerator_test(self, dev, port):
        pkt_accelerator_test(dev, port)

    @keyword
    def random_traffic_test(self, dev, port):
        random_traffic_test(dev, port)

    @keyword
    def pkt_trunc_test(self, dev, num, len, port):
        pkt_trunc_test(dev, num, len, port)

    @keyword
    def p4_bypass_port_num_test(self, dev, num, port, num_p4_proc):
        p4_bypass_port_num_test(dev, num, port, num_p4_proc)

    @keyword
    def phy_path_test(self, dev, num, port):
        phy_path_test(dev, num, port)

    @keyword
    def bypass_swap_test(self, dev, num, port):
        bypass_swap_test(dev, num, port)

    @keyword
    def smartnic_app_probes_test(self, dev, num, port):
        smartnic_app_probes_test(dev, num, port)

    @keyword
    def app_bypass_reconfig_test(self, dev, num, size, port):
        app_bypass_reconfig_test(dev, num, size, port)

    @keyword
    def hdr_length_reconfig_test(self, dev, num, size, port, num_p4_proc):
        hdr_length_reconfig_test(dev, num, size, port, num_p4_proc)

    @keyword
    def drops_to_bypass_test(self, dev, num, port):
        drops_to_bypass_test(dev, num, port)

    @keyword
    def drops_from_cmac_test(self, dev, num, size, port):
        drops_from_cmac_test(dev, num, size, port)

    @keyword
    def drops_to_host_test(self, dev, num, size, port):
        drops_to_host_test(dev, num, size, port)

    @keyword
    def drops_to_cmac_test(self, dev, num, size, port):
        drops_to_cmac_test(dev, num, size, port)

    @keyword
    def testcase_setup(self, dev, num_p4_proc):
        testcase_setup(dev, num_p4_proc)
        
    @keyword
    def testcase_teardown(self, dev):
        testcase_teardown(dev)

    @keyword
    def clear_switch_stats(self):
        clear_switch_stats()

    @keyword
    def hdr_length_config(self, dev, num_p4_proc, length):
        hdr_length_config(dev, num_p4_proc, length)


#===================================================================================================
# Basic traffic tests
#===================================================================================================
def pkt_playback_capture_test(dev, num, size, port, enable_probes=True):
    #clear_switch_stats()

    pkt_playback_config  (dev, port);  pkt_capture_config (dev, port)

    pkt_playback_capture (dev, num, size, port)

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                 'probe_to_pf0']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                 'probe_to_pf1']

    if enable_probes: check_probes (names, num, num*size)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_test(dev, port):
    # packet accelerator configuration.
    num  = 125
    size = random.randint(64, 512)

    tx_pkt = one_packet(size)

    pkt_accelerator_config (dev=dev, port=port, mux_out_sel=0, gt=False)  # mux_out_sel=0 (APP).
    pkt_accelerator_inject (dev, num, tx_pkt, port)

    time.sleep(0.5)  # wait in seconds, pkt_accelerator startup.

    _num  = 100
    _size = random.randint(64, 1500)
    if (port==0): _port = 1
    else:         _port = 0

    pkt_playback_capture_test (dev=dev, num=_num, size=_size, port=_port, enable_probes=False)

    pkt_accelerator_extract (dev, num, tx_pkt, port)
    #pkt_accelerator_flush (dev, port)

#---------------------------------------------------------------------------------------------------
def random_traffic_test(dev, port):
    if (port==0): _port = 1
    else:         _port = 0

    # packet accelerator configuration.
    num  = 300
    size = 64

    pkt_accelerator_config (dev=dev, port=_port, mux_out_sel=0, gt=False)  # mux_out_sel=0 (APP).

    # inject 'num' packets of increasing 'size' into packet accelerator.
    for j in range(num):
        tx_pkt = one_packet(size)

        pkt_accelerator_inject (dev, 1, tx_pkt, _port)  # 1 packet.

        size = size + 5  # spans short and long pkt sizes, and all 'tkeep' values.
        #print(f'Port {_port} - pkt_accelerator_inject - packet #{j} size: {size}')

    time.sleep(0.5)  # wait in seconds, pkt_accelerator startup.

    # run playback capture with random packet sizes.
    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    _bytes = rnd_playback_capture(dev=dev, num=100, port=port)

    # packet accelerator teardown.
    pkt_accelerator_flush (dev, _port)


#===================================================================================================
# P4 processor (p4_proc) tests
#===================================================================================================
def p4_bypass_port_num_test(dev, num, port, num_p4_proc):
    # Note: switching ports with 'port_num' reg is supported by:
    # 'p4_proc_igr' for 'p4_only' apps, or 'p4_proc_egr' for 'multi_proc' apps.

    # configure to 'swap' ports.
    if (num_p4_proc==2):
        if (port==0): dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_0 = 1
        else:         dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_1 = 0
    else:
        if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_0 = 1
        else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_1 = 0

    # configure mux/demux.
    pkt_playback_config (dev=dev, port=port, mux_out_sel=0)  # mux_out_sel=0 (APP).

    if (port==0): pkt_capture_config  (dev=dev, port=1)  # APP to PF1_VF2.
    else:         pkt_capture_config  (dev=dev, port=0)  # APP to PF0_VF2.

    bytes = rnd_playback_capture(dev, num, port)

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                 'probe_to_pf0', 'probe_to_host_0', 'probe_from_host_0', 'probe_from_pf0',
                 'probe_to_app_egr_p4_in0', 'probe_app0_to_core', 'probe_to_pf1_vf2']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                 'probe_to_pf1', 'probe_to_host_1', 'probe_from_host_1', 'probe_from_pf1',
                 'probe_to_app_egr_p4_in1', 'probe_app1_to_core', 'probe_to_pf0_vf2']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def pkt_trunc_test(dev, num, len, port):
    # configure for truncation length.
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.enable = 1
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.trunc_enable = 1
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.trunc_length = len

    pkt_playback_config (dev, port); pkt_capture_config  (dev, port)

    # playback 'num' packets of random 'size'.
    bytes_in  = 0; bytes_out = 0
    for j in range(num):
        size     = random.randint(64, 1500)
        bytes_in = bytes_in + size
        if (size < len): bytes_out = bytes_out + size
        else:            bytes_out = bytes_out + len
        #print(f'len: {len},  size: {size}, bytes_in: {bytes_in}, bytes_out: {bytes_out}')

        tx_pkt = one_packet(size)

        pkt_capture_trigger (dev)
        pkt_playback        (dev, tx_pkt, port, port)
        pkt_capture_read    (dev, tx_pkt[:len])

    # compare expected pkt and byte counts.
    if (port==0):
        check_probes (['probe_from_pf0_vf2'], num, bytes_in, False)  # disable ZERO checks.
        check_probes (['probe_to_pf0'],   num, bytes_out, False)
    else:
        check_probes (['probe_from_pf1_vf2'], num, bytes_in, False)
        check_probes (['probe_to_pf1'],   num, bytes_out, False)


#===================================================================================================
# Path and probe tests
#===================================================================================================
def phy_path_test(dev, num, port):
    pkt_playback_config (dev=dev, port=port, mux_out_sel=2)  # mux_out_sel=2 (BYPASS).
    pkt_capture_config (dev, port)

    cmac_loopback_config(dev=dev, port=port, enable=1, gt=False)  # enable smartnic cmac loopback.

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=0                        # BYPASS to PHY0.
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=0                    # PHY0 to APP.

    else:
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=0                        # BYPASS to PHY1.
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=0                    # PHY1 to APP.

    bytes = rnd_playback_capture(dev, num, port)

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_to_bypass_0', 'probe_to_cmac_0', 'probe_from_cmac_0',
                 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0']
    else:
        names = ['probe_from_pf1_vf2', 'probe_to_bypass_1', 'probe_to_cmac_1', 'probe_from_cmac_1',
                 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def bypass_swap_test(dev, num, port):
    dev.bar2.smartnic_regs.bypass_config.swap_paths = 1  # enable bypass swap.

    pkt_playback_config (dev=dev, port=port, mux_out_sel=2)  # mux_out_sel=2 (BYPASS).

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=1  # BYPASS to PF1_VF2.
        pkt_capture_config (dev=dev, port=1)
    else:
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=1  # BYPASS to PF0_VF2.
        pkt_capture_config (dev=dev, port=0)

    bytes = rnd_playback_capture(dev, num, port)

    # compare expected pkt and byte counts.
    if (port==0): names = ['probe_from_pf0_vf2', 'probe_to_bypass_0', 'probe_to_pf1_vf2']
    else:         names = ['probe_from_pf1_vf2', 'probe_to_bypass_1', 'probe_to_pf0_vf2']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
# Note: The following test assumes a default passthru mode for the 'smartnic_app_igr' and
#       'smartnic_app_egr' RTL functions.  This test should be omitted from the regression for
#       applications that fail this requirement.
#---------------------------------------------------------------------------------------------------
def smartnic_app_probes_test(dev, num, port):
    if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 0 # PHY0.
    else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 0 # PHY1.

    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    bytes = rnd_playback_capture(dev, num, port)

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                 'probe_to_app_igr_in0', 'probe_to_app_egr_in0', 'probe_to_app_egr_out0',
                 'probe_to_app_egr_p4_in0', 'probe_app0_to_core', 'probe_to_pf0_vf2']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                 'probe_to_app_igr_in1', 'probe_to_app_egr_in1', 'probe_to_app_egr_out1',
                 'probe_to_app_egr_p4_in1', 'probe_app1_to_core', 'probe_to_pf1_vf2']

    check_probes (names, num, bytes)


#===================================================================================================
# Reconfiguration tests
#===================================================================================================
def app_bypass_reconfig_test(dev, num, size, port):
    tx_pkt = []

    # configure and enable packet accelerator(s).
    for _port in range(2):
        tx_pkt.append(one_packet(size))

        if (port==2 or port==_port):
            pkt_accelerator_config (dev=dev, port=_port, mux_out_sel=2, gt=False)  # mux_out_sel=2 (BYPASS).
            pkt_accelerator_inject (dev, num, tx_pkt[_port], _port)

    # iteratively reconfigure 'mux_out_sel' while pkt accelerator runs.
    for i in range(10):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(0)  # PHY0 to APP.
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(0)  # PHY1 to APP.

        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(2)  # PHY0 to BYPASS.
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(2)  # PHY1 to BYPASS.

    # extract packets
    for _port in range(2):
        if (port==2 or port==_port):
            pkt_accelerator_extract (dev, num, tx_pkt[_port], _port)

#---------------------------------------------------------------------------------------------------
# Note: The smartnic datapath is NOT presently designed to pass the following test (Oct 3 2025, PB).
#---------------------------------------------------------------------------------------------------
def hdr_length_reconfig_test(dev, num, size, port, num_p4_proc):
    tx_pkt = []

    # configure and enable packet accelerator(s).
    for _port in range(2):
        tx_pkt.append(one_packet(size))

        if (port==2 or port==_port):
            pkt_accelerator_config (dev=dev, port=_port, mux_out_sel=0, gt=False)  # mux_out_sel=0 (APP).
            pkt_accelerator_inject (dev, num, tx_pkt[_port], _port)

    # iteratively reconfigure 'hdr_length' while pkt accelerator runs.
    for i in range(10):
        hdr_length_config(dev, num_p4_proc, 128)
        time.sleep(0.1) # wait in seconds, runtime before reconfig.

        hdr_length_config(dev, num_p4_proc, 0)
        time.sleep(0.1) # wait in seconds, runtime before reconfig.

    # extract packets
    for _port in range(2):
        if (port==2 or port==_port):
            pkt_accelerator_extract (dev, num, tx_pkt[_port], _port)


#===================================================================================================
# Packet drop tests
#===================================================================================================
def drops_to_bypass_test(dev, num, port):
    pkt_playback_config (dev, port)

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=3   # PF0_VF2 to BYPASS DROP
    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=3   # PF1_VF2 to BYPASS DROP

    bytes = rnd_playback (dev, num, port)  # playback 'num' packets of random 'size'.

    if (port==0): names = ['probe_from_pf0_vf2', 'drops_to_bypass_0']
    else:         names = ['probe_from_pf1_vf2', 'drops_to_bypass_1']

    # compare expected pkt and byte counts.
    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def drops_from_cmac_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl).

    # configure datapath to buffer PHY traffic in ingress FIFOs.
    pkt_playback_config (dev=dev, port=port, mux_out_sel=2)       # mux_out_sel=2 (BYPASS).
    cmac_loopback_config(dev=dev, port=port, enable=1, gt=False)  # enable smartnic cmac loopback.

    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=2   # PHY0 to BYPASS.
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=2   # PHY1 to BYPASS.

    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 1  # assert 'tpause' to igr FIFOs.

    # send packets.
    tx_pkt = one_packet(size)
    for i in range(num): pkt_playback (dev, tx_pkt, 2+port, port)  # playback from PF (2=PF0, 3=PF1).

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core',
                 'probe_to_cmac_0']
    else:
        names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core',
                 'probe_to_cmac_1']

    bytes = num * size
    check_probes (names, num, bytes, False)  # disable ZERO checks.

    if (port==0): names = ['drops_ovfl_from_cmac_0']
    else:         names = ['drops_ovfl_from_cmac_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64)+1) # also accounts for buffering in open-nic-shell.
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, False)  # disable ZERO checks.

    # release and capture packets held in ingress FIFOs.
    pkt_capture_config (dev, port)
    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 0  # deassert 'tpause' to igr FIFOs.

    for i in range(_num):
        pkt_capture_trigger (dev)
        pkt_capture_read (dev, tx_pkt)

    # compare expected pkt and byte counts.
    if (port==0): names = ['probe_from_cmac_0', 'probe_to_bypass_0', 'probe_to_pf0_vf2']
    else:         names = ['probe_from_cmac_1', 'probe_to_bypass_1', 'probe_to_pf1_vf2']

    bytes = _num * size
    check_probes (names, _num, bytes, False)  # disable ZERO checks.

    # validate that subsequent traffic passes properly.
    pkt_playback_capture_test (dev=dev, num=10, size=size, port=port, enable_probes=False)

#---------------------------------------------------------------------------------------------------
def drops_to_host_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl)

    # configure datapath to buffer HOST traffic in egress FIFOs.
    pkt_playback_config  (dev, port);

    if (port==0):
        dev.bar2.smartnic_regs.switch_config.host_0_lpbk_enable = 0
        dev.bar2.smartnic_regs.switch_config.axis_to_host_0_tpause = 1  # assert 'tpause' to egr FIFO.
    else:
        dev.bar2.smartnic_regs.switch_config.host_1_lpbk_enable = 0
        dev.bar2.smartnic_regs.switch_config.axis_to_host_1_tpause = 1  # assert 'tpause' to egr FIFO.

    # send packets.
    tx_pkt = one_packet(size)
    for i in range(num): pkt_playback (dev, tx_pkt, port, port)

    # compare expected pkt and byte counts.
    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0',
                 'probe_to_pf0']

    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1',
                 'probe_to_pf1']

    bytes = num * size
    check_probes (names, num, bytes, False)  # disable ZERO checks.

    if (port==0): names = ['drops_ovfl_to_host_0']
    else:         names = ['drops_ovfl_to_host_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64))
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, False)  # disable ZERO checks.

    if (port==0): names = ['probe_to_host_0']
    else:         names = ['probe_to_host_1']

    bytes = _num * size
    check_probes (names, _num, bytes, False)  # disable ZERO checks.

#---------------------------------------------------------------------------------------------------
def drops_to_cmac_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl)

    pkt_playback_config (dev, port);  # configure for playback, but keep CMACs disabled.

    # send packets.
    tx_pkt = one_packet(size)
    for i in range(num):
        pkt_playback (dev, tx_pkt, 2+port, port)  # playback from PF (2=PF0, 3=PF1).

    # compare expected pkt and byte counts.
    if (port==0): names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core']
    else:         names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core']

    bytes = num * size
    check_probes (names, num, bytes, False)  # disable ZERO checks.

    if (port==0): names = ['drops_ovfl_to_cmac_0']
    else:         names = ['drops_ovfl_to_cmac_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64)+2) # also accounts for buffering in open-nic-shell.
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, False)  # disable ZERO checks.

    if (port==0): names = ['probe_to_cmac_0']
    else:         names = ['probe_to_cmac_1']

    bytes = _num * size
    check_probes (names, _num, bytes, False)  # disable ZERO checks.

#---------------------------------------------------------------------------------------------------
