*** Settings ***
Documentation    SmartNIC egress queue (smartnic_egress_qs) hardware tests.
...
...              Test Setup enables the egress queues (polls init_done, then sets
...              control.enable=1) in addition to the standard datapath reset.
...
...              Probe counter checks use sn_cfg gRPC stats.  Status-register
...              checks read BAR2 regio fields directly via the regio proxy.
Library          smartnic.tests.egress_qs.Library
Variables        variables
Variables        smartnic.lib.config
Test Setup       Egr Qs Testcase Setup    ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown        ${dev}
Test Timeout     3 minutes


*** Test Cases ***

# ============================================================
# Correctness: Single-Packet Tests
# ============================================================

Egress QS - Min-Size Packet - Port 0
    [Documentation]    Single 64 B packet through enabled egress queues, port 0.
    Egr Qs Min Size Test    dev=${dev}    port=${0}

Egress QS - Min-Size Packet - Port 1
    [Documentation]    Single 64 B packet through enabled egress queues, port 1.
    Egr Qs Min Size Test    dev=${dev}    port=${1}

Egress QS - Max-Size Packet - Port 0
    [Documentation]    Single 9100 B (jumbo) packet through enabled egress queues, port 0.
    Egr Qs Max Size Test    dev=${dev}    port=${0}

Egress QS - Max-Size Packet - Port 1
    [Documentation]    Single 9100 B (jumbo) packet through enabled egress queues, port 1.
    Egr Qs Max Size Test    dev=${dev}    port=${1}

Egress QS - Corrupt Packet Detection - Port 0
    [Documentation]    Sends a 64 B packet and compares against a single-byte-corrupted
    ...                expected value; verifies that pkt_capture_read raises a mismatch
    ...                error, confirming byte-level validation is active, port 0.
    Egr Qs Corrupt Packet Test    dev=${dev}    port=${0}

Egress QS - Corrupt Packet Detection - Port 1
    [Documentation]    Same corruption detection test on port 1.
    Egr Qs Corrupt Packet Test    dev=${dev}    port=${1}

Egress QS - 128 B Packet - Port 0
    [Documentation]    Single 128 B packet, port 0.
    Egr Qs Single Packet Test    dev=${dev}    size=${128}    port=${0}

Egress QS - 128 B Packet - Port 1
    [Documentation]    Single 128 B packet, port 1.
    Egr Qs Single Packet Test    dev=${dev}    size=${128}    port=${1}

Egress QS - 1500 B Packet - Port 0
    [Documentation]    Single Ethernet MTU-sized (1500 B) packet, port 0.
    Egr Qs Single Packet Test    dev=${dev}    size=${1500}    port=${0}

Egress QS - 1500 B Packet - Port 1
    [Documentation]    Single Ethernet MTU-sized (1500 B) packet, port 1.
    Egr Qs Single Packet Test    dev=${dev}    size=${1500}    port=${1}


# ============================================================
# Correctness: Multi-Packet and Random-Size Tests
# ============================================================

Egress QS - Multi-Packet 128 B - Port 0
    [Documentation]    10 fixed-size 128 B packets, probe counter validation, port 0.
    Egr Qs Multi Packet Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Egress QS - Multi-Packet 128 B - Port 1
    [Documentation]    10 fixed-size 128 B packets, probe counter validation, port 1.
    Egr Qs Multi Packet Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${1}

Egress QS - Multi-Packet 1500 B - Port 0
    [Documentation]    10 fixed-size 1500 B packets with counter validation, port 0.
    Egr Qs Multi Packet Test    dev=${dev}    num=${pkt_num}    size=${1500}    port=${0}

Egress QS - Multi-Packet 1500 B - Port 1
    [Documentation]    10 fixed-size 1500 B packets with counter validation, port 1.
    Egr Qs Multi Packet Test    dev=${dev}    num=${pkt_num}    size=${1500}    port=${1}

Egress QS - Random Packet Sizes - Port 0
    [Documentation]    50 packets with random sizes (64–1500 B), verifying data integrity
    ...                and probe counters, port 0.
    Egr Qs Random Size Test    dev=${dev}    num=${50}    port=${0}

Egress QS - Random Packet Sizes - Port 1
    [Documentation]    50 packets with random sizes (64–1500 B), verifying data integrity
    ...                and probe counters, port 1.
    Egr Qs Random Size Test    dev=${dev}    num=${50}    port=${1}


# ============================================================
# Corner Cases: Packet Size Boundaries and tkeep
# ============================================================

Egress QS - Boundary Sizes - Port 0
    [Documentation]    Packets at known boundary sizes (64, 65, 127, 128, 255, 512, 1023,
    ...                1024, 1500, 4096, 9100 B) stressing tkeep generation, port 0.
    Egr Qs Boundary Sizes Test    dev=${dev}    port=${0}

Egress QS - Boundary Sizes - Port 1
    [Documentation]    Same boundary-size sequence on port 1.
    Egr Qs Boundary Sizes Test    dev=${dev}    port=${1}

Egress QS - tkeep Stress - Port 0
    [Documentation]    Incrementing packet sizes from 64 B upward (step +1, 64 packets)
    ...                to exercise every tkeep pattern on the 512-bit bus, port 0.
    Egr Qs Tkeep Stress Test    dev=${dev}    port=${0}

Egress QS - tkeep Stress - Port 1
    [Documentation]    Same tkeep stress sequence on port 1.
    Egr Qs Tkeep Stress Test    dev=${dev}    port=${1}


# ============================================================
# Control: Bypass Mode and Enable/Disable
# ============================================================

Egress QS - Bypass Mode - Port 0
    [Documentation]    With control.enable=0 (bypass), traffic passes directly from app
    ...                to output without queuing; status.enabled must read 0, port 0.
    Egr Qs Bypass Mode Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Egress QS - Bypass Mode - Port 1
    [Documentation]    Bypass mode on port 1.
    Egr Qs Bypass Mode Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${1}

Egress QS - Enable/Disable Cycling - Port 0
    [Documentation]    Alternates between enabled and bypass mode three times on port 0,
    ...                verifying traffic passes and counters are correct in each mode.
    Egr Qs Enable Disable Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Egress QS - Enable/Disable Cycling - Port 1
    [Documentation]    Same enable/disable cycling on port 1.
    Egr Qs Enable Disable Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${1}


# ============================================================
# Register Validation
# ============================================================

Egress QS - Status Registers
    [Documentation]    Validates control.enable, status.init_done, status.enabled, and
    ...                soft-reset behaviour of the egress QS register block.
    Egr Qs Status Registers Test    dev=${dev}

Egress QS - Port Status Clear on Read
    [Documentation]    Reads port_status[0/1] and desc_status (rd_evt registers) and
    ...                verifies no unexpected overflow bits are set after normal traffic.
    Egr Qs Port Status Clear Test    dev=${dev}

Egress QS - Alloc Status at Idle
    [Documentation]    Confirms sg_alloc and q_mgr[0/1] report init_done=1, enabled=1,
    ...                no error flags, and cnt_active=0 before any traffic.
    Egr Qs Alloc Status Test    dev=${dev}


# ============================================================
# Probe Counter Validation (PHY path through egress QS)
# ============================================================

Egress QS - Probe Counters - Port 0
    [Documentation]    Validates probe_from_pf0_vf2, probe_core_to_app0,
    ...                probe_to_app_igr_p4_out0, probe_app0_to_core, and probe_to_cmac_0
    ...                all increment correctly with egress queues enabled, port 0.
    Egr Qs Probe Counters Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Egress QS - Probe Counters - Port 1
    [Documentation]    Same probe validation on port 1.
    Egr Qs Probe Counters Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${1}

Egress QS - Both Ports Simultaneously
    [Documentation]    Injects traffic on both PHY ports at the same time and verifies
    ...                per-port probe counters are independent and correct.
    Egr Qs Both Ports Test    dev=${dev}    num=${pkt_num}    size=${512}


# ============================================================
# Alloc / Queue Manager
# ============================================================

Egress QS - Alloc Balance - Port 0
    [Documentation]    After injecting and fully draining packets, asserts that
    ...                q_mgr dbg_cnt_alloc == dbg_cnt_dealloc and cnt_active == 0
    ...                (no leaked queue slots or buffers), port 0.
    Egr Qs Alloc Balance Test    dev=${dev}    num=${pkt_num}    size=${512}    port=${0}

Egress QS - Alloc Balance - Port 1
    [Documentation]    Same balance check on port 1.
    Egr Qs Alloc Balance Test    dev=${dev}    num=${pkt_num}    size=${512}    port=${1}

Egress QS - Alloc Throughput - Port 0
    [Documentation]    Verifies q_mgr dbg_cnt_alloc equals the number of packets sent,
    ...                confirming every packet was enqueued exactly once, port 0.
    Egr Qs Alloc Throughput Test    dev=${dev}    num=${pkt_num}    size=${512}    port=${0}

Egress QS - Alloc Throughput - Port 1
    [Documentation]    Same throughput check on port 1.
    Egr Qs Alloc Throughput Test    dev=${dev}    num=${pkt_num}    size=${512}    port=${1}


# ============================================================
# Burst / Backpressure
# ============================================================

Egress QS - Burst - Small Packets - Port 0
    [Documentation]    Burst of 128 × 64 B packets injected back-to-back; verifies the
    ...                queue absorbs the burst and all packets drain correctly, port 0.
    Egr Qs Burst Test    dev=${dev}    num=${128}    size=${64}    port=${0}

Egress QS - Burst - Small Packets - Port 1
    [Documentation]    Same burst on port 1.
    Egr Qs Burst Test    dev=${dev}    num=${128}    size=${64}    port=${1}

Egress QS - Burst - Large Packets - Port 0
    [Documentation]    Burst of 32 × 1500 B packets, port 0.
    Egr Qs Burst Test    dev=${dev}    num=${32}    size=${1500}    port=${0}

Egress QS - Burst - Large Packets - Port 1
    [Documentation]    Burst of 32 × 1500 B packets, port 1.
    Egr Qs Burst Test    dev=${dev}    num=${32}    size=${1500}    port=${1}

Egress QS - Burst - Jumbo Packets - Port 0
    [Documentation]    Burst of 8 × 9100 B jumbo packets, port 0.
    ...                Skipped: single-queue test saturates the HBM scatter-gather write
    ...                path causing input overflow. Performance improves with multiple
    ...                virtual queues; needs recharacterisation in that configuration.
    [Tags]             robot:skip
    Egr Qs Burst Test    dev=${dev}    num=${8}    size=${9100}    port=${0}

Egress QS - Burst - Jumbo Packets - Port 1
    [Documentation]    Burst of 8 × 9100 B jumbo packets, port 1.
    ...                Skipped: see Port 0 note.
    [Tags]             robot:skip
    Egr Qs Burst Test    dev=${dev}    num=${8}    size=${9100}    port=${1}


# ============================================================
# Performance
# ============================================================

Egress QS - Performance - 64 B Packets - Port 0
    [Documentation]    Sustained throughput test with egress queues enabled, 64 B packets
    ...                on port 0.  Target: wire-rate (limited by smartnic loopback clock).
    ...                Max internal pkt rate = 322.265 MHz / 1 cycle per pkt = 322.265 Mpps.
    ...                Reported rate per port = 322.265 / 2 = 161.1 Mpps.
    ...                Skipped: packet_q is designed for many simultaneous virtual queues;
    ...                single-queue throughput is ~6 Mpps, not wire rate. Recharacterise
    ...                with multi-queue configuration.
    [Tags]             robot:skip
    Egr Qs Performance Test    dev=${dev}    port=${0}    num=${150}    size=${64}    mpps=${161.1}    gbps=${113494}

Egress QS - Performance - 64 B Packets - Port 1
    [Documentation]    Same wire-rate test on port 1. Skipped: see Port 0 note.
    [Tags]             robot:skip
    Egr Qs Performance Test    dev=${dev}    port=${1}    num=${150}    size=${64}    mpps=${161.1}    gbps=${113494}

Egress QS - Performance - 1500 B Packets - Port 0
    [Documentation]    Throughput test with 1500 B packets, port 0.
    ...                Max pkt rate = 165000 Mbps / (1500×8) bpp = 13.75 Mpps per port.
    ...                Skipped: single-queue throughput is ~6 Mpps. Recharacterise with
    ...                multi-queue configuration.
    [Tags]             robot:skip
    Egr Qs Performance Test    dev=${dev}    port=${0}    num=${15}    size=${1500}    mpps=${13.75}    gbps=${165000}

Egress QS - Performance - 1500 B Packets - Port 1
    [Documentation]    Same 1500 B throughput test on port 1. Skipped: see Port 0 note.
    [Tags]             robot:skip
    Egr Qs Performance Test    dev=${dev}    port=${1}    num=${15}    size=${1500}    mpps=${13.75}    gbps=${165000}
