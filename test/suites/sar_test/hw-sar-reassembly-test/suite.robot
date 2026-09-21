*** Settings ***
Documentation    SAR reassembly path tests for the sar_test example design.
Library          sar_test.tests.sar_reassembly.Library
Variables        variables
Test Setup       Testcase Setup      ${dev}
Test Teardown    Testcase Teardown   ${dev}
Test Timeout     2 minutes


*** Test Cases ***
# ----------------------------
# Sanity / register check
# ----------------------------
SAR Reassembly - Register Sanity
    SAR Reassembly Sanity Test    dev=${dev}


# ----------------------------
# Single-segment frames
# ----------------------------
SAR Reassembly - Single Segment Frame - 64B
    SAR Reassembly Single Segment Test    dev=${dev}    buf_id=${0}    frame_size=${64}

SAR Reassembly - Single Segment Frame - 512B
    SAR Reassembly Single Segment Test    dev=${dev}    buf_id=${1}    frame_size=${512}


# ----------------------------
# Multi-segment frames
# ----------------------------
SAR Reassembly - In-Order Multi-Segment Frame
    SAR Reassembly Multi Segment In Order Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${4096}    seg_len=${512}

SAR Reassembly - In-Order Multi-Segment Frame - Large
    SAR Reassembly Multi Segment In Order Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${9216}    seg_len=${512}

SAR Reassembly - Out-Of-Order Segments
    SAR Reassembly Multi Segment Out Of Order Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${4096}    seg_len=${512}


# ----------------------------
# Multi-frame / interleaved
# ----------------------------
SAR Reassembly - Multiple Frames Interleaved
    SAR Reassembly Multi Frame Interleaved Test
    ...    dev=${dev}    num_frames=${4}    frame_size=${2048}    seg_len=${512}


# ----------------------------
# Timeout / error handling
# ----------------------------
SAR Reassembly - Fragment Timeout
    [Timeout]    30 seconds
    SAR Reassembly Timeout Test    dev=${dev}    buf_id=${0}    timeout_ms=${50}


# ----------------------------
# Debug counter verification
# ----------------------------
SAR Reassembly - Debug Counters
    SAR Reassembly Debug Counters Test
    ...    dev=${dev}    num_frames=${10}    frame_size=${1536}    seg_len=${512}
