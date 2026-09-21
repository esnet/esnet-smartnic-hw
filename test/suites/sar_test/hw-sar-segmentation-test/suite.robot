*** Settings ***
Documentation    SAR segmentation path tests for the sar_test example design.
Library          sar_test.tests.sar_segmentation.Library
Variables        variables
Test Setup       Testcase Setup      ${dev}
Test Teardown    Testcase Teardown   ${dev}
Test Timeout     2 minutes


*** Test Cases ***
# ----------------------------
# Sanity / register check
# ----------------------------
SAR Segmentation - Register Sanity
    SAR Segmentation Sanity Test    dev=${dev}


# ----------------------------
# Single-segment frames
# ----------------------------
SAR Segmentation - Single Segment Frame - 64B
    SAR Segmentation Single Segment Test    dev=${dev}    buf_id=${0}    frame_size=${64}

SAR Segmentation - Single Segment Frame - 512B
    SAR Segmentation Single Segment Test    dev=${dev}    buf_id=${0}    frame_size=${512}


# ----------------------------
# Multi-segment frames
# ----------------------------
SAR Segmentation - Multi-Segment Frame - 4096B
    SAR Segmentation Multi Segment Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${4096}    seg_len=${512}

SAR Segmentation - Multi-Segment Frame - 9216B
    SAR Segmentation Multi Segment Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${9216}    seg_len=${512}


# ----------------------------
# Boundary conditions
# ----------------------------
SAR Segmentation - Segment Length Boundary
    SAR Segmentation Boundary Test    dev=${dev}    buf_id=${0}    seg_len=${512}


# ----------------------------
# Segment length reconfiguration
# ----------------------------
SAR Segmentation - Configure Segment Length - 512 to 256
    SAR Segmentation Configure Seg Len Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${3000}    new_seg_len=${256}

SAR Segmentation - Configure Segment Length - 512 to 128
    SAR Segmentation Configure Seg Len Test
    ...    dev=${dev}    buf_id=${0}    frame_size=${1024}    new_seg_len=${128}


# ----------------------------
# Sequential frames across buffers
# ----------------------------
SAR Segmentation - Sequential Frames - All Buffer IDs
    SAR Segmentation Sequential Frames Test    dev=${dev}    num_frames=${4}


# ----------------------------
# Debug counter verification
# ----------------------------
SAR Segmentation - Debug Counters
    SAR Segmentation Debug Counters Test    dev=${dev}    num_frames=${5}
