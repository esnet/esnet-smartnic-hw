*** Settings ***
Documentation    Basic datapath tests.
Library          hw.datapath.Library
Variables        variables
Test Setup       Testcase Setup       ${dev}
Test Teardown    Testcase Teardown    ${dev}


*** Test Cases ***
Packet Playback And Capture Tests
    Clear Switch Stats
    Pkt Playback Capture Test    ${dev}    ${num}    ${size}    ${0}
    Pkt Playback Capture Test    ${dev}    ${num}    ${size}    ${1}

Packet Accelerator Tests
    Pkt Accelerator Test    ${dev}    ${0}
    Pkt Accelerator Test    ${dev}    ${1}
