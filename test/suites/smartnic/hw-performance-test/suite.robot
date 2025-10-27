*** Settings ***
Documentation    Smartnic performance tests.
Library          smartnic.performance.Library
Variables        variables
Variables        smartnic.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute

# Note: all platform performance tests have 'P4 Bypass' mode configured in test setup.



#=== GT-based Performance Test Cases ===
*** Comments ***
# ----------------------------
# App Bypass Mode Tests
# ----------------------------
App Bypass Mode - Both Ports - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    Performance Test    dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}    mux_out_sel=${2}

App Bypass Mode - Both Ports - 1472B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((1472+4+20)x8) bpp = 8.36 Mpps.
    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${8.36}     gbps=${100000}    mux_out_sel=${2}



# ----------------------------
# HdrLen 0 Tests (no hdr split-join)
# ----------------------------
HdrLen 0 - Both Ports - 64B Pkts
    Performance Test    dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}

HdrLen 0 - Both Ports - 1472B Pkts
# Max internal data rate = 343.75MHz x 512b = 176000 Mbps (shared through p4_bypass_mux)
# Max internal pkt rate = 176000 Mbps / (1472x8) bpp = 14.946 Mpps (shared through p4_bypass_mux).
# Max CMAC pkt rate = 14.946 Mpps / 2 ports = 7.473 Mpps
# Max CMAC data rate = 7.473 Mpps x ((1472+4+20)x8) bpp = 89437 Gbps.
    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${7.473}    gbps=${89437}



# ----------------------------
# HdrLen 64 Tests
# ----------------------------
HdrLen 64 - Both Ports - 64B Pkts
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}

HdrLen 64 - Both Ports - 65B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((65+4+20)x8) bpp = 140.4 Mpps.
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${150}    size=${65}      mpps=${140.4}    gbps=${100000}

HdrLen 64 - Both Ports - 1472B Pkts
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}     mpps=${8.36}     gbps=${100000}









#==== Smartnic Loopback Performance Test Cases ===
# Performance tests targets with smartnic cmac loopback enabled (gt=False).
*** Test Cases ***
# ----------------------------
# App Bypass Mode Tests
# ----------------------------
App Bypass Mode - Both Ports - 64B Pkts
# Max internal data rate = 322.265 MHz x 512b = 165000 Mbps.
# Max internal pkt rate = 165000 Mbps / (64x8) bpp = 322.265 Mpps.
# Reported data rate = 322.265 Mpps * (64+4+20)x8 bpp = 226875 Mbps.
    Performance Test    dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${322.3}    gbps=${226875}    mux_out_sel=${2}

App Bypass Mode - Both Ports - 1472B Pkts
# Max internal pkt rate = 165000 Mbps / (1472x8) bpp = 14.01 Mpps.
# Reported data rate = 14.01 Mpps * (1472+4+20)x8 bpp = 167671 Mpps.
    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${14.0}     gbps=${167671}    mux_out_sel=${2}



# ----------------------------
# HdrLen 0 Tests (no hdr split-join)
# ----------------------------
HdrLen 0 - Both Ports - 64B Pkts
# Max internal data rate = 343.75MHz x 512b = 176000 Mbps (shared through p4_bypass_mux)
# Max internal pkt rate = 176000 Mbps / (64x8) bpp = 343.75 Mpps (shared through p4_bypass_mux).
# Max port pkt rate = 343.75 Mpps / 2 ports = 171.875 Mpps
# Reported port data rate = 171.875 Mpps x ((64+4+20)x8) bpp = 121000 Gbps.
    Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${171.9}    gbps=${121000}

HdrLen 0 - Both Ports - 1472B Pkts
# Max internal pkt rate = 176000 Mbps / (1472x8) bpp = 14.946 Mpps (shared through p4_bypass_mux).
# Max port pkt rate = 14.946 Mpps / 2 ports = 7.473 Mpps
# Reported port data rate = 7.473 Mpps x ((1472+4+20)x8) bpp = 89437 Gbps.
    Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${7.473}    gbps=${89437}



# ----------------------------
# HdrLen 64 Tests
# ----------------------------
HdrLen 64 - Both Ports - 64B Pkts
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${171.9}    gbps=${121000}

HdrLen 64 - Both Ports - 65B Pkts
# Max internal pkt rate = 322.265 MHz / 2 cycles per pkt = 161.1325 Mpps.
# Reported port data rate = 161.1325 Mpps x ((65+4+20)x8) bpp = 114726 Gbps.
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${150}    size=${65}      mpps=${161.1}    gbps=${114726}

HdrLen 64 - Both Ports - 1472B Pkts
    Hdr Length Config    dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${14.0}     gbps=${167671}
