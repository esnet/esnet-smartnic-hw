*** Settings ***
Documentation    Basic datapath tests.
Library          hw.performance.Library
Variables        variables
Test Setup       Testcase Setup       ${dev}
Test Teardown    Testcase Teardown    ${dev}


*** Test Cases ***
# The following cases seem to expose an intermittent capture read problem.
P4 Mode, 64B-Headers - Port 0 - 65B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((65+4+20)x8) bpp = 140.4 Mpps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${0}    ${150}    ${65}    ${140.4}    ${100000}

P4 Mode, 64B-Headers - Port 1 - 65B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((65+4+20)x8) bpp = 140.4 Mpps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${1}    ${150}    ${65}    ${140.4}    ${100000}

P4 Mode, 64B-Headers - Both Ports - 65B Pkts
# Max P4 pkt rate = 171.8 Mpps (shared). Max pkt rate per port = 171.8/2 = 85.9 Mpps.
# Max byte rate per port = 85.9 Mpps x (65+4+20)x8 bpp = 61161 Mbps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${2}    ${150}    ${65}     ${85.9}     ${61161}



# The following cases seem to expose an intermittent capture read problem.
P4 Mode, 64B-Headers - Port 0 - 69B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((69+4+20)x8) bpp = 134.4 Mpps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${0}    ${150}    ${69}    ${134.4}    ${100000}

P4 Mode, 64B-Headers - Port 1 - 69B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((69+4+20)x8) bpp = 134.4 Mpps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${1}    ${150}    ${69}    ${134.4}    ${100000}

P4 Mode, 64B-Headers - Both Ports - 69B Pkts
# Max P4 pkt rate = 171.8 Mpps (shared). Max pkt rate per port = 171.8/2 = 85.9 Mpps.
# Max byte rate per port = 85.9 Mpps x (69+4+20)x8 bpp = 63909 Mbps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${2}    ${150}    ${69}     ${85.9}     ${63909}



P4 Bypass Mode - Port 0 - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    P4 Bypass Config    ${dev}    ${1}
#   Performance Test      dev,   port,      num,    size,       mpps,        gbps.
    Performance Test    ${dev}    ${0}    ${150}    ${64}    ${142.0}    ${100000}

P4 Bypass Mode - Port 1 - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    P4 Bypass Config    ${dev}    ${1}
    Performance Test    ${dev}    ${1}    ${150}    ${64}    ${142.0}    ${100000}

P4 Bypass Mode - Both Ports - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    P4 Bypass Config    ${dev}    ${1}
    Performance Test    ${dev}    ${2}    ${150}    ${64}    ${142.0}    ${100000}



P4 Mode - Port 0 - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    Performance Test    ${dev}    ${0}    ${150}    ${64}    ${142.0}    ${100000}

P4 Mode - Port 1 - 64B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((64+4+20)x8) bpp = 142.0 Mpps.
    Performance Test    ${dev}    ${1}    ${150}    ${64}    ${142.0}    ${100000}

P4 Mode - Both Ports - 64B Pkts
# Max P4 pkt rate = 171.8 Mpps (shared). Max pkt rate per port = 171.8/2 = 85.9 Mpps.
# Max byte rate per port = 85.9 Mpps x (64+4+20)x8 bpp = 60474 Mbps.
    Performance Test    ${dev}    ${2}    ${150}    ${64}     ${85.9}     ${60474}



App Bypass Mode - Both Ports - 1472B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((1472+4+20)x8) bpp = 8.36 Mpps.
#   Performance Test      dev,   port,     num,      size,      mpps,         gbps,    mux_out_sel.
    Performance Test    ${dev}    ${2}    ${15}    ${1472}    ${8.36}     ${100000}    ${2}

P4 Mode, 64B-Headers - Both Ports - 1472B Pkts
# Max CMAC pkt rate = 100000 Mbps / ((1472+4+20)x8) bpp = 8.36 Mpps.
    Hdr Length Config    ${dev}    ${64}
    Performance Test     ${dev}    ${2}   ${15}    ${1472}    ${8.36}     ${100000}



*** Comments ***
# The following cases are limited by the P4 processor and have unexplained results.
# As such, these cases are omitted from the regression suite for now.

#P4 Mode - Both Ports - 65B Pkts
# Max P4 pkt rate = 159 Mpps (shared). Max pkt rate per port = 159/2 = 79.5 Mpps.
# Max byte rate per port = 79.5 Mpps x (65+4+20)x8 bpp = 56604 Mbps.
# PASSES. But lower Max P4 pkt rate for this case?
#    Performance Test     ${dev}    ${2}    ${150}    ${65}     ${79.5}     ${56604}

#P4 Mode - Both Ports - 1472B Pkts
# Max P4 pkt rate = 171500 Mbps / (1472x8) bpp = 14.56 Mpps (7.28 Mpps per port).
# Max CMAC bit rate = 7.28 Mpps x (1472+4+20)x8 bpp = 87127 Mbps
# CMAC0 packet rate 6.875080150152554 did NOT match expected?
#    Performance Test     ${dev}    ${2}    ${15}    ${1472}    ${7.28}    ${87127}
