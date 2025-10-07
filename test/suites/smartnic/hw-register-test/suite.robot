*** Settings ***
Documentation    Basic register tests.
Library          smartnic.registers.Library
Variables        variables
Variables        smartnic.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute

*** Test Cases ***
FW Bytes to Word Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Unpacked to Packed    dev=${dev}    exp_data=${0x11223344}
        Endian Check Unpacked to Packed    dev=${dev}    exp_data=${0x44332211}
    END

FW Word to Bytes Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Packed to Unpacked    dev=${dev}    exp_data=${0x44332211}
        Endian Check Packed to Unpacked    dev=${dev}    exp_data=${0x11223344}
    END
