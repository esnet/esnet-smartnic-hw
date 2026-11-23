*** Settings ***
Documentation    Smartnic performance tests.
Library          smartnic.tests.performance.Library
Variables        variables
Variables        smartnic.lib.config
Test Setup       Testcase Setup       ${dev}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute


# Note: all platform performance tests have 'P4 Bypass' mode configured in test setup.

*** Test Cases ***
# GT Loopback Performance Tests
# i.e. performance tests targets with gt loopback enabled (gt=True).

# ----------------------------
# App Bypass Mode Tests
# ----------------------------
GT Loop Performance - App Bypass Mode - Both Ports - 64B Pkts
# Limited by MAC throughput.
    IF    ${VERSAL}
        # Max DCMAC pkt rate = 200000 Mbps / ((64+4+20)x8) bpp = 284.0 Mpps.
        Performance Test     dev=${dev}    port=${2}    num=${300}    size=${64}      mpps=${284.0}    gbps=${200000}    gt={True}    mux_out_sel=${2}
    ELSE
        # Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}    gt={True}    mux_out_sel=${2}
    END

GT Loop Performance - App Bypass Mode - Both Ports - 1472B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((1472+4+20)x8) bpp = 8.36 Mpps.
    Skip If    ${VERSAL}
    Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${8.36}     gbps=${100000}    gt={True}    mux_out_sel=${2}


# ----------------------------
# HdrLen 0 Tests (no hdr split-join)
# ----------------------------
GT Loop Performance - HdrLen 0 - Both Ports - 64B Pkts
    IF    ${VERSAL}
        # Limited by p4_bypass_mux throughput.
        # Max internal data rate = 350MHz x 512b = 179200 Mbps (shared through p4_bypass_mux)
        # Max internal pkt rate = 179200 Mbps / (64x8) bpp = 350 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 350 Mpps / 2 ports = 175 Mpps
        # Reported port data rate = 175 Mpps x ((64+4+20)x8) bpp = 123200 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${300}    size=${64}      mpps=${175.0}    gbps=${123200}    gt={True}
    ELSE
        # Limited by MAC throughput.
        # Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}    gt=${True}
    END

GT Loop Performance - HdrLen 0 - Both Ports - 1472B Pkts
# Max internal data rate = 343.75MHz x 512b = 176000 Mbps (shared through p4_bypass_mux)
# Max internal pkt rate = 176000 Mbps / (1472x8) bpp = 14.946 Mpps (shared through p4_bypass_mux).
# Max CMAC pkt rate = 14.946 Mpps / 2 ports = 7.473 Mpps
# Max CMAC data rate = 7.473 Mpps x ((1472+4+20)x8) bpp = 89437 Gbps.
    Skip If    ${VERSAL}
    Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${7.473}    gbps=${89437}     gt=${True}


# ----------------------------
# HdrLen 64 Tests
# ----------------------------
GT Loop Performance - HdrLen 64 - Both Ports - 64B Pkts
    Hdr Length Config    dev=${dev}    length=${64}
    IF    ${VERSAL}
        # Limited by p4_bypass_mux throughput.
        # Max internal data rate = 350MHz x 512b = 179200 Mbps (shared through p4_bypass_mux)
        # Max internal pkt rate = 179200 Mbps / (64x8) bpp = 350 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 350 Mpps / 2 ports = 175 Mpps
        # Reported port data rate = 175 Mpps x ((64+4+20)x8) bpp = 123200 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${300}    size=${64}      mpps=${175.0}    gbps=${123200}    gt={True}
    ELSE
        # Limited by MAC throughput.
        # Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${142.0}    gbps=${100000}    gt=${True}
    END

GT Loop Performance - HdrLen 64 - Both Ports - 65B Pkts
    Skip If    ${VERSAL}
    Hdr Length Config    dev=${dev}    length=${64}
    IF    ${VERSAL}
        # Limited by p4_bypass_mux throughput????
        # Max port pkt rate = 350 Mpps / 2 ports = 175 Mpps
        # Reported port data rate = 175 Mpps x ((65+4+20)x8) bpp = 124600 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${300}    size=${65}      mpps=${175.0}    gbps=${124600}    gt={True}
    ELSE
        # Limited by MAC throughput.
        # Max CMAC pkt rate = 100000 Mbps / ((65+4+20)x8) bpp = 140.4 Mpps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${65}      mpps=${140.4}    gbps=${100000}    gt=${True}
    END


GT Loop Performance - HdrLen 64 - Both Ports - 1472B Pkts
    Skip If    ${VERSAL}
    Hdr Length Config    dev=${dev}    length=${64}
    Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}     mpps=${8.36}     gbps=${100000}    gt=${True}







# Smartnic Loopback Performance Tests
# i.e. performance tests targets with smartnic cmac loopback enabled (gt=False).

# ----------------------------
# App Bypass Mode Tests
# ----------------------------
Smartnic Loop Performance - App Bypass Mode - Both Ports - 64B Pkts
    # Limited by CMAC FIFO throughput.
    IF    ${VERSAL}
        # Max internal data rate = 350 MHz x 512b = 179200 Mbps.
        # Max internal pkt rate = 179200 Mbps / (64x8) bpp = 350 Mpps.
        # Reported data rate = 350 Mpps * (64+4+20)x8 bpp = 246400 Mbps.
        Performance Test    dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${350}      gbps=${246400}    mux_out_sel=${2}
    ELSE
        # Max internal data rate = 322.265 MHz x 512b = 165000 Mbps.
        # Max internal pkt rate = 165000 Mbps / (64x8) bpp = 322.265 Mpps.
        # Reported data rate = 322.265 Mpps * (64+4+20)x8 bpp = 226875 Mbps.
        Performance Test    dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${322.3}    gbps=${226875}    mux_out_sel=${2}
    END

Smartnic Loop Performance - App Bypass Mode - Both Ports - 1472B Pkts
    # Limited by CMAC FIFO throughput.
    IF    ${VERSAL}
        # Max internal pkt rate = 179200 Mbps / (1472x8) bpp = 15.2174 Mpps.
        # Reported data rate = 15.2174 Mpps * (1472+4+20)x8 bpp = 182122 Mbps.
        Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${15.2}     gbps=${182122}    mux_out_sel=${2}
    ELSE
        # Max internal pkt rate = 165000 Mbps / (1472x8) bpp = 14.01 Mpps.
        # Reported data rate = 14.01 Mpps * (1472+4+20)x8 bpp = 167671 Mbps.
        Performance Test    dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${14.0}     gbps=${167671}    mux_out_sel=${2}
    END


# ----------------------------
# HdrLen 0 Tests (no hdr split-join)
# ----------------------------
Smartnic Loop Performance - HdrLen 0 - Both Ports - 64B Pkts
    # Limited by p4_bypass_mux throughput.
    IF    ${VERSAL}
        # Max internal data rate = 350MHz x 512b = 179200 Mbps (shared through p4_bypass_mux)
        # Max internal pkt rate = 179200 Mbps / (64x8) bpp = 350 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 350 Mpps / 2 ports = 175 Mpps
        # Reported port data rate = 175 Mpps x ((64+4+20)x8) bpp = 123200 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${175}      gbps=${123200}
    ELSE
        # Max internal data rate = 343.75MHz x 512b = 176000 Mbps (shared through p4_bypass_mux)
        # Max internal pkt rate = 176000 Mbps / (64x8) bpp = 343.75 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 343.75 Mpps / 2 ports = 171.875 Mpps
        # Reported port data rate = 171.875 Mpps x ((64+4+20)x8) bpp = 121000 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${171.9}    gbps=${121000}
    END

Smartnic Loop Performance - HdrLen 0 - Both Ports - 1472B Pkts
    # Limited by p4_bypass_mux throughput.
    IF    ${VERSAL}
        # Max internal pkt rate = 179200 Mbps / (1472x8) bpp = 15.2174 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 15.2174 Mpps / 2 ports = 7.6087 Mpps
        # Reported port data rate = 7.6087 Mpps x ((1472+4+20)x8) bpp = 91061 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${7.609}    gbps=${91061}
    ELSE
        # Max internal pkt rate = 176000 Mbps / (1472x8) bpp = 14.9457 Mpps (shared through p4_bypass_mux).
        # Max port pkt rate = 14.9457 Mpps / 2 ports = 7.47285 Mpps
        # Reported port data rate = 7.47285 Mpps x ((1472+4+20)x8) bpp = 89435 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${7.473}    gbps=${89435}
    END


# ----------------------------
# HdrLen 64 Tests
# ----------------------------
Smartnic Loop Performance - HdrLen 64 - Both Ports - 64B Pkts
    # Limited by p4_bypass_mux throughput.  See calculations above.
    Hdr Length Config    dev=${dev}    length=${64}
    IF    ${VERSAL}
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${175}      gbps=${123200}
    ELSE
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${64}      mpps=${171.9}    gbps=${121000}
    END

Smartnic Loop Performance - HdrLen 64 - Both Ports - 65B Pkts
    Hdr Length Config    dev=${dev}    length=${64}
    IF    ${VERSAL}
        # Limited by p4_bypass_mux throughput.
        # Max internal pkt rate = 350 MHz / 2 cycles per pkt = 175 Mpps.
        # Reported port data rate = 175 Mpps x ((65+4+20)x8) bpp = 124600 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${65}      mpps=${175}      gbps=${124600}
    ELSE
        # Limited by CMAC FIFO throughput.
        # Max internal pkt rate = 322.265 MHz / 2 cycles per pkt = 161.1325 Mpps.
        # Reported port data rate = 161.1325 Mpps x ((65+4+20)x8) bpp = 114726 Gbps.
        Performance Test     dev=${dev}    port=${2}    num=${150}    size=${65}      mpps=${161.1}    gbps=${114726}
    END

Smartnic Loop Performance - HdrLen 64 - Both Ports - 1472B Pkts
    # Limited by CMAC FIFO throughput.  See calculations above.
    Hdr Length Config    dev=${dev}    length=${64}
    IF    ${VERSAL}
        Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${15.2}     gbps=${182122}
    ELSE
        Performance Test     dev=${dev}    port=${2}    num=${15}     size=${1472}    mpps=${14.0}     gbps=${167671}
    END
