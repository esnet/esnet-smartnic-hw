*** Settings ***
Documentation    Smartnic datapath tests.
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
Datapath - Packet Playback Capture Test - Port 0
    Pkt Playback Capture Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Datapath - Packet Accelerator Test - Port 0
    Pkt Accelerator Test    dev=${dev}    port=${0}

Datapath - Packet Accelerator Test - Port 1
    Pkt Accelerator Test    dev=${dev}    port=${1}

Datapath - HdrLen 0 - Random Traffic - Port 0
    Random Traffic Test     dev=${dev}    port=${0}

Datapath - HdrLen 0 - Random Traffic - Port 1
    Random Traffic Test     dev=${dev}    port=${1}

Datapath - HdrLen 64 - Random Traffic - Port 0
    Hdr Length Config       dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Random Traffic Test     dev=${dev}    port=${0}

Datapath - HdrLen 64 - Random Traffic - Port 1
    Hdr Length Config       dev=${dev}    num_p4_proc=${num_p4_proc}    length=${64}
    Random Traffic Test     dev=${dev}    port=${1}

Datapath - HdrLen 192 - Random Traffic - Port 0
    Hdr Length Config       dev=${dev}    num_p4_proc=${num_p4_proc}    length=${192}
    Random Traffic Test     dev=${dev}    port=${0}

Datapath - HdrLen 192 - Random Traffic - Port 1
    Hdr Length Config       dev=${dev}    num_p4_proc=${num_p4_proc}    length=${192}
    Random Traffic Test     dev=${dev}    port=${1}


# ----------------------------
# P4 Processor Tests
# ----------------------------
Datapath - P4 Bypass Port Num - Port 0
    P4 Bypass Port Num Test     dev=${dev}    num=${pkt_num}    port=${0}    num_p4_proc=${num_p4_proc}

Datapath - P4 Bypass Port Num - Port 1
    P4 Bypass Port Num Test     dev=${dev}    num=${pkt_num}    port=${1}    num_p4_proc=${num_p4_proc}

Datapath - Packet Truncation - Port 0
    Pkt Trunc Test              dev=${dev}    num=${pkt_num}    len=${pkt_size}    port=${0}

Datapath - Packet Truncation - Port 1
    Pkt Trunc Test              dev=${dev}    num=${pkt_num}    len=${pkt_size}    port=${1}


# ----------------------------
# Path and Probe Tests
# ----------------------------
Datapath - PHY Path Test - Port 0
    PHY Path Test               dev=${dev}    num=${pkt_num}    port=${0}

Datapath - PHY Path Test - Port 1
    PHY Path Test               dev=${dev}    num=${pkt_num}    port=${1}

Datapath - Bypass Swap Test - Port 0
    Bypass Swap Test            dev=${dev}    num=${pkt_num}    port=${0}

Datapath - Bypass Swap Test - Port 1
    Bypass Swap Test            dev=${dev}    num=${pkt_num}    port=${1}

Datapath - Smartnic App Probes Test - Port 0
    Smartnic App Probes Test    dev=${dev}    num=${pkt_num}    port=${0}

Datapath - Smartnic App Probes Test - Port 1
    Smartnic App Probes Test    dev=${dev}    num=${pkt_num}    port=${1}


# ----------------------------
# Reconfiguration Tests
# ----------------------------
Datapath - App Bypass Reconfig Test - Both Ports
    App Bypass Reconfig Test    dev=${dev}    num=${15}    size=${1472}    port=${2}

# Note: the smartnic datapath is NOT presently designed to pass the following test (Oct 3 2025, PB).
#Datapath - Hdr Length Reconfig Test - Both Ports
#    Hdr Length Reconfig Test    dev=${dev}    num=${15}    size=${1472}    port=${2}    num_p4_proc=${num_p4_proc}


# ----------------------------
# Packet drop Tests
# ----------------------------
Datapath - Drops To Bypass Test - Port 0
    Drops To Bypass Test    dev=${dev}    num=${pkt_num}    port=${0}

Datapath - Drops To Bypass Test - Port 1
    Drops To Bypass Test    dev=${dev}    num=${pkt_num}    port=${1}

Datapath - Drops From CMAC Test - Port 0
    Drops From CMAC Test    dev=${dev}    num=${75}    size=${1500}    port=${0}

Datapath - Drops From CMAC Test - Port 1
    Drops From CMAC Test    dev=${dev}    num=${75}    size=${1500}    port=${1}

Datapath - Drops To Host Test - Port 0
    Drops To Host Test      dev=${dev}    num=${75}    size=${1500}    port=${0}

Datapath - Drops To Host Test - Port 1
    Drops To Host Test      dev=${dev}    num=${75}    size=${1500}    port=${1}

Datapath - Drops To CMAC Test - Port 0
    Drops To CMAC Test      dev=${dev}    num=${75}    size=${1500}    port=${0}

Datapath - Drops To CMAC Test - Port 1
    Drops To CMAC Test      dev=${dev}    num=${75}    size=${1500}    port=${1}



*** Comments ***
Zero Length Packet Test - Port 0
    Pkt Playback Capture Test    dev=${dev}    num=${1}          size=${0}      port=${0}

Packet Playback Capture Test - Port 0
    Pkt Playback Capture Test    dev=${dev}    num=${pkt_num}    size=${128}    port=${0}

Drops From CMAC Test - Port 0
    Drops From CMAC Test    dev=${dev}    num=${75}    size=${1500}    port=${0}
