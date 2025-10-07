*** Settings ***
Documentation    Smartnic performance tests.
Library          smartnic.performance.Library
Variables        variables
Variables        smartnic.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute



*** Test Cases ***
# Note: all platform performance tests have 'P4 Bypass' mode configured in test setup.

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

#HdrLen 0 - Both Ports - 1472B Pkts
#    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${8.36}     gbps=${100000}
#    Performance Test    ${dev}    ${2}     ${15}    ${1472}    ${7.47}     ${100000}



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
    Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${8.36}     gbps=${100000}
