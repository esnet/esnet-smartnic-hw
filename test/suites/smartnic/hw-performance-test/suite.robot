*** Settings ***
Documentation    Basic datapath tests.
Library          smartnic.performance.Library
Variables        variables
Variables        smartnic.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}


*** Test Cases ***
# All platform performance tests have 'P4 Bypass' mode configured at startup.

# ----------------------------
# App Bypass Mode Tests
# ----------------------------
App Bypass Mode - Both Ports - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
   #Performance Test      dev,   port,     num,      size,      mpps,         gbps,    mux_out_sel.
    Performance Test    ${dev}    ${2}    ${150}    ${64}    ${142.0}     ${100000}    ${2}

App Bypass Mode - Both Ports - 1472B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((1472+4+20)x8) bpp = 8.36 Mpps.
    Performance Test    ${dev}    ${2}    ${15}    ${1472}    ${8.36}     ${100000}    ${2}



# ----------------------------
# HdrLen 0 Tests (no pkt header split-join)
# ----------------------------
HdrLen 0 - Both Ports - 64B Pkts
    Performance Test    ${dev}    ${2}    ${150}    ${64}      ${142.0}    ${100000}

#HdrLen 0 - Both Ports - 1472B Pkts
   #Performance Test    ${dev}    ${2}     ${15}    ${1472}    ${8.36}     ${100000}



# ----------------------------
# HdrLen 64 Tests
# ----------------------------
HdrLen 64 - Both Ports - 64B Pkts
   #Hdr Length Config    ${dev}    ${p4_proc}    ${length}
    Hdr Length Config    ${dev}    igr           ${64}
    Run Keyword If    ${num_p4_proc} == ${2}    Hdr Length Config    ${dev}    egr        ${64}

    Performance Test     ${dev}    ${2}    ${150}    ${64}      ${142.0}    ${100000}

HdrLen 64 - Both Ports - 65B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((65+4+20)x8) bpp = 140.4 Mpps.
    Hdr Length Config    ${dev}    igr        ${64}
    Run Keyword If    ${num_p4_proc} == ${2}    Hdr Length Config    ${dev}    egr        ${64}

    Performance Test     ${dev}    ${2}    ${150}    ${65}      ${140.4}    ${100000}

HdrLen 64 - Both Ports - 1472B Pkts
    Hdr Length Config    ${dev}    igr        ${64}
    Run Keyword If    ${num_p4_proc} == ${2}    Hdr Length Config    ${dev}    egr        ${64}

    Performance Test     ${dev}    ${2}    ${15}     ${1472}    ${8.36}     ${100000}
