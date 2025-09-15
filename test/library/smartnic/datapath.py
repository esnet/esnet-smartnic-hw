__all__ = ()

from robot.api.deco import keyword, library

from smartnic.config  import *
from smartnic.packets import *
from smartnic.probes  import *

import time
import math

#---------------------------------------------------------------------------------------------------
@library
class Library:
    @keyword
    def pkt_playback_capture_test(self, dev, num, size, port, enable_probes=1):
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
    def p4_bypass_port_type_test(self, dev, num, port):
        p4_bypass_port_type_test(dev, num, port)

    @keyword
    def p4_bypass_port_num_test(self, dev, num, port, num_p4_proc):
        p4_bypass_port_num_test(dev, num, port, num_p4_proc)

    @keyword
    def phy_path_test(self, dev, num, port):
        phy_path_test(dev, num, port)

    @keyword
    def probe_to_host_test(self, dev, num, port):
        probe_to_host_test(dev, num, port)

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
    def hdr_length_config(self, dev, p4_proc, length):
        hdr_length_config(dev, p4_proc, length)



#---------------------------------------------------------------------------------------------------
# basic traffic tests
#---------------------------------------------------------------------------------------------------
def pkt_playback_capture_test(dev, num, size, port, enable_probes=1):
    clear_switch_stats()

    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    pkt_playback_capture (dev, num, size, port)

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_app_igr_in0',
                 'probe_to_app_egr_in0', 'probe_to_app_egr_out0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core',
                 'probe_to_pf0_vf2']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_app_igr_in1',
                 'probe_to_app_egr_in1', 'probe_to_app_egr_out1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core',
                 'probe_to_pf1_vf2']

    if (enable_probes==1): check_probes (names, num, num*size)

#---------------------------------------------------------------------------------------------------
def pkt_accelerator_test(dev, port):
    num  = 125
    size = random.randint(64, 512)

    tx_pkt = one_packet(size)

    pkt_accelerator_config (dev, port, 0)  # mux_out_sel = 0 (APP)
    pkt_accelerator_inject (dev, num, tx_pkt, port)

    time.sleep(1) # wait in seconds, pkt_accelerator run time.

    _num  = 100
    _size = random.randint(64, 1500)
    if (port==0): _port = 1
    else:         _port = 0

    pkt_playback_capture_test (dev, _num, _size, _port, 0)  # disable probes.

    pkt_accelerator_extract (dev, num, tx_pkt, port)
    #pkt_accelerator_flush (dev, port)

#---------------------------------------------------------------------------------------------------
def random_traffic_test(dev, port):
    if (port==0): _port = 1
    else:         _port = 0

    # packet accelerator configuration.
    num  = 125   # number of pkts injected.
    size = 64    # initial pkt size injected.

    pkt_accelerator_config (dev, _port, 0)  # mux_out_sel = 0 (APP)

    # inject packets into packet accelerator.
    for j in range(num):
        tx_pkt = one_packet(size)

        pkt_accelerator_inject (dev, 1, tx_pkt, _port)

        size = size + 7
        #print(f'size: {size}')

    time.sleep(1) # wait in seconds, pkt_accelerator startup time.

    # run playback capture with random packet sizes.
    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    _bytes = rnd_playback_capture(dev, 100, port)

    # packet accelerator teardown.
    pkt_accelerator_flush (dev, _port)



#---------------------------------------------------------------------------------------------------
# p4_proc tests
#---------------------------------------------------------------------------------------------------
def p4_bypass_port_type_test(dev, num, port):
    if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 1 # PF0
    else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 1 # PF1

    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    bytes = rnd_playback_capture(dev, num, port)

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def p4_bypass_port_num_test(dev, num, port, num_p4_proc):
    # switching ports with 'port_num' reg is supported by 'p4_proc_igr' for 'p4_only' apps, or
    #                                                     'p4_proc_egr' for 'multi_proc' apps.
    if (num_p4_proc==2):
        if (port==0): dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_0 = 1
        else:         dev.bar2.p4_proc_egr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_1 = 0
    else:
        if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_0 = 1
        else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_num_1 = 0

    # configure mux/demux for port_num.
    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=0
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=1
    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=0
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=1

    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    bytes = rnd_playback_capture(dev, num, port)

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_app_igr_in0',
                 'probe_to_app_egr_in0', 'probe_to_app_egr_out0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core',
                 'probe_to_pf1_vf2']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_app_igr_in1',
                 'probe_to_app_egr_in1', 'probe_to_app_egr_out1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core',
                 'probe_to_pf0_vf2']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def pkt_trunc_test(dev, num, len, port):
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.enable = 1
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.trunc_enable = 1
    dev.bar2.p4_proc_igr.p4_proc.trunc_config.trunc_length = len

    pkt_capture_config  (dev, port)
    pkt_playback_config (dev, port)

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

        result = pkt_capture_read (dev, tx_pkt[:len])
        if (result != True): raise AssertionError(f'Packet data received did NOT match expected!')
        
    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        check_probes (['probe_from_pf0_vf2'], num, bytes_in, 0)  # disable ZERO checks
        check_probes (['probe_to_pf0_vf2'],   num, bytes_out, 0)
    else:
        check_probes (['probe_from_pf1_vf2'], num, bytes_in, 0)
        check_probes (['probe_to_pf1_vf2'],   num, bytes_out, 0)



#---------------------------------------------------------------------------------------------------
# path and probe tests
#---------------------------------------------------------------------------------------------------
def phy_path_test(dev, num, port):
    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=2                    # PF0_VF2 to BYPASS
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port0=0                        # BYPASS to PHY0
        cmac_loopback_config(dev, port)                                              # PHY0 to PHY0
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=0                    # PHY0 to APP
        dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 1  # APP to PF0

    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=2                    # PF1_VF2 to BYPASS
        dev.bar2.smartnic_regs.smartnic_demux_out_sel.port1=0                        # BYPASS to PHY1
        cmac_loopback_config(dev, port)                                              # PHY1 to PHY1
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=0                    # PHY1 to APP
        dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 1  # APP to PF1

    bytes = rnd_playback_capture(dev, num, port)

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_to_bypass_0', 'probe_to_cmac_0', 'probe_from_cmac_0',
                 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0']
    else:
        names = ['probe_from_pf1_vf2', 'probe_to_bypass_1', 'probe_to_cmac_1', 'probe_from_cmac_1',
                 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def probe_to_host_test(dev, num, port):
    if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 1 # PF0
    else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 1 # PF1

    pkt_playback_config (dev, port);
    bytes = 0
    for i in range(num):
        size   = random.randint(64, 1500)
        bytes  = bytes + size
        tx_pkt = one_packet(size)

        pkt_playback (dev, tx_pkt, port, port)

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0',
                 'probe_to_host_0']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1',
                 'probe_to_host_1']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def bypass_swap_test(dev, num, port):
    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)

    dev.bar2.smartnic_regs.bypass_config.swap_paths = 1

    if (port==0):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[2]._r.value=int(2)               # PF0_VF2 to BYPASS
        cmac_loopback_config(dev, 1)                                                 # BYPASS to PHY1
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(0)               # PHY1 to APP
        dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 1  # APP to PF1

    else:
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[3]._r.value=int(2)               # PF1_VF2 to BYPASS
        cmac_loopback_config(dev, 0)                                                 # BYPASS to PHY0
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(0)               # PHY0 to APP
        dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 1  # APP to PF0

    bytes = rnd_playback_capture(dev, num, port)

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_to_bypass_0', 'probe_to_cmac_1', 'probe_from_cmac_1',
                 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1']
    else:
        names = ['probe_from_pf1_vf2', 'probe_to_bypass_1', 'probe_to_cmac_0', 'probe_from_cmac_0',
                 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
# Note: The following test assumes a default passthru mode for the 'smartnic_app_igr' and 'smartnic_app_egr'
#       RTL functions, and should be omitted from the regression for applications failing this requirement.
#---------------------------------------------------------------------------------------------------
def smartnic_app_probes_test(dev, num, port):
    pkt_playback_config (dev, port);  pkt_capture_config (dev, port)
    bytes = rnd_playback_capture(dev, num, port)

    if (port==0):
        names = ['probe_from_pf0_vf2', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_app_igr_in0',
                 'probe_to_app_egr_in0', 'probe_to_app_egr_out0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core',
                 'probe_to_pf0_vf2']
    else:
        names = ['probe_from_pf1_vf2', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_app_igr_in1',
                 'probe_to_app_egr_in1', 'probe_to_app_egr_out1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core',
                 'probe_to_pf1_vf2']

    check_probes (names, num, bytes)



#---------------------------------------------------------------------------------------------------
# reconfiguration tests
#---------------------------------------------------------------------------------------------------
def app_bypass_reconfig_test(dev, num, size, port):
    tx_pkt = []

    # configure and enable packet accelerator(s).
    for _port in range(2):
        tx_pkt.append(one_packet(size))

        if (port==2 or port==_port):
            pkt_accelerator_config (dev, _port, 2)  # mux_out_sel = 2 (BYPASS).
            pkt_accelerator_inject (dev, num, tx_pkt[_port], _port)

    # iteratively reconfigure mux_out_sel while pkt accelerator runs.
    for i in range(10):
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(0)  # PHY0 to APP
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(0)  # PHY1 to APP

        dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=int(2)  # PHY0 to BYPASS
        dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=int(2)  # PHY1 to BYPASS

    # extract packets
    for _port in range(2):
        if (port==2 or port==_port):
            pkt_accelerator_extract (dev, num, tx_pkt[_port], _port)
            #pkt_accelerator_flush (dev, _port)
            time.sleep(1)

#---------------------------------------------------------------------------------------------------
def hdr_length_reconfig_test(dev, num, size, port, num_p4_proc):
    tx_pkt = []

    # configure and enable packet accelerator(s).
    for _port in range(2):
        tx_pkt.append(one_packet(size))

        if (port==2 or port==_port):
            pkt_accelerator_config (dev, _port, 2)  # mux_out_sel = 2 (BYPASS).
            pkt_accelerator_inject (dev, num, tx_pkt[_port], _port)

    # iteratively reconfigure mux_out_sel while pkt accelerator runs.
    for i in range(10):
        hdr_length_config(dev, 'igr', 128)
        if (num_p4_proc == 2): hdr_length_config(dev, 'egr', 128)

        time.sleep(0.01) # wait in seconds, for hdr_length config.

        hdr_length_config(dev, 'igr', 0)
        if (num_p4_proc == 2): hdr_length_config(dev, 'egr', 0)

        time.sleep(0.01) # wait in seconds, for hdr_length config.

    # extract packets
    for _port in range(2):
        if (port==2 or port==_port):
            pkt_accelerator_extract (dev, num, tx_pkt[_port], _port)
            #pkt_accelerator_flush (dev, _port)
            time.sleep(1)



#---------------------------------------------------------------------------------------------------
# Packet drop tests
#---------------------------------------------------------------------------------------------------
def drops_to_bypass_test(dev, num, port):
    pkt_playback_config (dev, port)
    cmac_loopback_config(dev, port)

    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=3   # PHY0 to BYPASS DROP
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=3   # PHY1 to BYPASS DROP

    bytes = 0
    for i in range(num):
        size   = random.randint(64, 1500)
        bytes  = bytes + size
        tx_pkt = one_packet(size)

        pkt_playback (dev, tx_pkt, 2+port, port)  # playback pkt to ingress PF interface i.e. 2=PF0, 3=PF1.

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core',
                 'probe_to_cmac_0', 'probe_from_cmac_0', 'drops_to_bypass_0']
    else:
        names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core',
                 'probe_to_cmac_1', 'probe_from_cmac_1', 'drops_to_bypass_1']

    check_probes (names, num, bytes)

#---------------------------------------------------------------------------------------------------
def drops_from_cmac_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl)

    pkt_playback_config  (dev, port);
    cmac_loopback_config (dev, port)

    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=2   # PHY0 to BYPASS
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=2   # PHY1 to BYPASS

    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 1  # assert tpause from 'p4_proc_igr' to igr FIFOs.

    tx_pkt = one_packet(size)
    for i in range(num):
        pkt_playback (dev, tx_pkt, 2+port, port)  # playback from igr PF i/f (2=PF0, 3=PF1).

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0): names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core', 'probe_to_cmac_0']
    else:         names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core', 'probe_to_cmac_1']

    bytes = num * size
    check_probes (names, num, bytes, 0)  # disable ZERO checks.

    if (port==0): names = ['drops_ovfl_from_cmac_0']
    else:         names = ['drops_ovfl_from_cmac_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64)+1)
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, 0)  # disable ZERO checks.


    pkt_capture_config (dev, port)
    dev.bar2.smartnic_regs.switch_config.igr_sw_tpause = 0  # assert tpause from 'p4_proc_igr' to igr FIFOs.

    result=True
    for i in range(_num):
        pkt_capture_trigger (dev)
        result = result and pkt_capture_read (dev, tx_pkt)
    if (result != True): raise AssertionError(f'Packet data received did NOT match expected!')

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0): names = ['probe_from_cmac_0', 'probe_to_bypass_0', 'probe_to_pf0_vf2']
    else:         names = ['probe_from_cmac_1', 'probe_to_bypass_1', 'probe_to_pf1_vf2']

    bytes = _num * size
    check_probes (names, _num, bytes, 0)  # disable ZERO checks.


    pkt_playback_capture_test (dev, 10, size, port, 0)  # disable probe checks.

#---------------------------------------------------------------------------------------------------
def drops_to_host_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl)

    pkt_playback_config  (dev, port);
    cmac_loopback_config (dev, port)

    if (port==0): dev.bar2.smartnic_regs.smartnic_mux_out_sel[0]._r.value=0  # PHY0 to APP
    else:         dev.bar2.smartnic_regs.smartnic_mux_out_sel[1]._r.value=0  # PHY1 to APP

    if (port==0): dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_0 = 1 # PF0
    else:         dev.bar2.p4_proc_igr.p4_proc.p4_bypass_config.p4_bypass_egr_port_type_1 = 1 # PF1

    dev.bar2.smartnic_regs.switch_config.axis_to_host_0_tpause = 1  # assert 'tpause' to igr FIFOs.
    dev.bar2.smartnic_regs.switch_config.axis_to_host_1_tpause = 1

    tx_pkt = one_packet(size)
    for i in range(num):
        pkt_playback (dev, tx_pkt, 2+port, port)  # playback from igr PF i/f (2=PF0, 3=PF1).

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0):
        names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core', 'probe_to_cmac_0',
                 'probe_from_cmac_0', 'probe_core_to_app0', 'probe_to_app_igr_p4_out0', 'probe_to_pf0']
    else:
        names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core', 'probe_to_cmac_1',
                 'probe_from_cmac_1', 'probe_core_to_app1', 'probe_to_app_igr_p4_out1', 'probe_to_pf1']

    bytes = num * size
    check_probes (names, num, bytes, 0)  # disable ZERO checks.


    if (port==0): names = ['drops_ovfl_to_host_0']
    else:         names = ['drops_ovfl_to_host_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64))
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, 0)  # disable ZERO checks.

    if (port==0): names = ['probe_to_host_0']
    else:         names = ['probe_to_host_1']

    bytes = _num * size
    check_probes (names, _num, bytes, 0)  # disable ZERO checks.

#---------------------------------------------------------------------------------------------------
def drops_to_cmac_test(dev, num, size, port):
    FIFO_DEPTH = 1306 # 1024-4 (fifo_async) + 2x143 (axi4s_pkt_discard_ovfl)

    pkt_playback_config  (dev, port);

    tx_pkt = one_packet(size)
    for i in range(num):
        pkt_playback (dev, tx_pkt, 2+port, port)  # playback from igr PF i/f (2=PF0, 3=PF1).

    time.sleep(1) # wait in seconds, for stats collection.

    if (port==0): names = ['probe_from_pf0', 'probe_to_app_egr_p4_in0', 'probe_app0_to_core']
    else:         names = ['probe_from_pf1', 'probe_to_app_egr_p4_in1', 'probe_app1_to_core']

    bytes = num * size
    check_probes (names, num, bytes, 0)  # disable ZERO checks.

    if (port==0): names = ['drops_ovfl_to_cmac_0']
    else:         names = ['drops_ovfl_to_cmac_1']

    _num = math.ceil(FIFO_DEPTH/math.ceil(size/64)+2)
    bytes = (num-_num) * size
    check_probes (names, (num-_num), bytes, 0)  # disable ZERO checks.

    if (port==0): names = ['probe_to_cmac_0']
    else:         names = ['probe_to_cmac_1']

    bytes = _num * size
    check_probes (names, _num, bytes, 0)  # disable ZERO checks.

#---------------------------------------------------------------------------------------------------
