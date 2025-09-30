*** Settings ***
Documentation    Basic datapath tests.
Library          smartnic.datapath.Library
Variables        variables
Variables        smartnic.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute



*** Test Cases ***
# ----------------------------
# Basic Traffic Tests
# ----------------------------
Packet Accelerator Test - Port 0
    Pkt Accelerator Test    ${dev}    ${0}

Packet Accelerator Test - Port 1
    Pkt Accelerator Test    ${dev}    ${1}

HdrLen 0 - Random Traffic - Port 0
    Random Traffic Test     ${dev}    ${0}

HdrLen 0 - Random Traffic - Port 1
    Random Traffic Test     ${dev}    ${1}

HdrLen 64 - Random Traffic - Port 0
    Hdr Length Config       ${dev}    igr    ${64}
    Random Traffic Test     ${dev}    ${0}

HdrLen 64 - Random Traffic - Port 1
    Hdr Length Config       ${dev}    igr    ${64}
    Random Traffic Test     ${dev}    ${1}

HdrLen 192 - Random Traffic - Port 0
    Hdr Length Config       ${dev}    igr    ${192}
    Random Traffic Test     ${dev}    ${0}

HdrLen 192 - Random Traffic - Port 1
    Hdr Length Config       ${dev}    igr    ${192}
    Random Traffic Test     ${dev}    ${1}



# ----------------------------
# P4 Processor Tests
# ----------------------------
P4 Bypass Port Type - Port 0
   #P4 Bypass Port Type Test    ${dev}    ${num}    ${port}
    P4 Bypass Port Type Test    ${dev}    ${num}    ${0}

P4 Bypass Port Type - Port 1
    P4 Bypass Port Type Test    ${dev}    ${num}    ${1}

P4 Bypass Port Num - Port 0
   #P4 Bypass Port Num Test     ${dev}    ${num}    ${port}    ${num_p4_proc}
    P4 Bypass Port Num Test     ${dev}    ${num}    ${0}       ${num_p4_proc}

P4 Bypass Port Num - Port 1
    P4 Bypass Port Num Test     ${dev}    ${num}    ${1}       ${num_p4_proc}

Packet Truncation - Port 0
   #Pkt Trunc Test    ${dev}    ${num}    ${len}    ${port}
    Pkt Trunc Test    ${dev}    ${num}    ${size}   ${0}

Packet Truncation - Port 1
    Pkt Trunc Test    ${dev}    ${num}    ${size}   ${1}



# ----------------------------
# Path and Probe Tests
# ----------------------------
PHY Path Test - Port 0
   #PHY Path Test    ${dev}    ${num}    ${port}
    PHY Path Test    ${dev}    ${num}    ${0}

PHY Path Test - Port 1
    PHY Path Test    ${dev}    ${num}    ${1}

Probe To Host Test - Port 0
   #Probe To Host Test    ${dev}    ${num}    ${port}
    Probe To Host Test    ${dev}    ${num}    ${0}

Probe To Host Test - Port 1
    Probe To Host Test    ${dev}    ${num}    ${1}

Bypass Swap Test - Port 0
   #Bypass Swap Test    ${dev}    ${num}    ${port}
    Bypass Swap Test    ${dev}    ${num}    ${0}

Bypass Swap Test - Port 1
    Bypass Swap Test    ${dev}    ${num}    ${1}

Smartnic App Probes Test - Port 0
   #Smartnic App Probes Test    ${dev}    ${num}    ${port}
    Smartnic App Probes Test    ${dev}    ${num}    ${0}

Smartnic App Probes Test - Port 1
    Smartnic App Probes Test    ${dev}    ${num}    ${1}



# ----------------------------
# Reconfiguration Tests
# ----------------------------
App Bypass Reconfig Test - Both Ports
   #App Bypass Reconfig Test    ${dev}    ${num}    ${size}    ${port}
    App Bypass Reconfig Test    ${dev}    ${15}     ${1472}    ${2}

Hdr Length Reconfig Test - Both Ports
   #Hdr Length Reconfig Test    ${dev}    ${num}    ${size}    ${port}    ${num_p4_proc}
    Hdr Length Reconfig Test    ${dev}    ${15}     ${1472}    ${2}       ${num_p4_proc}



# ----------------------------
# Packet drop Tests
# ----------------------------
Drops To Bypass Test - Port 0
   #Drops To Bypass Test    ${dev}    ${num}    ${port}
    Drops To Bypass Test    ${dev}    ${num}    ${0}

Drops To Bypass Test - Port 1
    Drops To Bypass Test    ${dev}    ${num}    ${1}

Drops From CMAC Test - Port 0
   #Drops From CMAC Test    ${dev}    ${num}    ${size}    ${port}
    Drops From CMAC Test    ${dev}    ${75}     ${1500}    ${0}

Drops From CMAC Test - Port 1
    Drops From CMAC Test    ${dev}    ${75}     ${1500}    ${1}

Drops To Host Test - Port 0
   #Drops To Host Test    ${dev}    ${num}    ${size}    ${port}
    Drops To Host Test    ${dev}    ${75}     ${1500}    ${0}

Drops To Host Test - Port 1
    Drops To Host Test    ${dev}    ${75}     ${1500}    ${1}

Drops To CMAC Test - Port 0
   #Drops To CMAC Test    ${dev}    ${num}    ${size}    ${port}
    Drops To CMAC Test    ${dev}    ${75}     ${1500}    ${0}

Drops To CMAC Test - Port 1
    Drops To CMAC Test    ${dev}    ${75}     ${1500}    ${1}



*** comments ***
Zero Length Packet Test - Port 0
    Pkt Playback Capture Test    ${dev}    ${1}    ${0}    ${0}

Packet Playback Capture Test - Port 0
    Pkt Playback Capture Test    ${dev}    ${num}    ${128}    ${0}