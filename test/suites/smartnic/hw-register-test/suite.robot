*** Settings ***
Documentation    Basic register tests.
Library          smartnic.tests.registers.Library
Variables        variables
Variables        smartnic.lib.config
Test Setup       Testcase Setup       ${dev}    ${num_p4_proc}
Test Teardown    Testcase Teardown    ${dev}
Test Timeout     1 minute

*** Test Cases ***
Registers - FW Bytes to Word Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Unpacked to Packed    dev=${dev}    exp_data=${0x11223344}
        Endian Check Unpacked to Packed    dev=${dev}    exp_data=${0x44332211}
    END

Registers - FW Word to Bytes Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Packed to Unpacked    dev=${dev}    exp_data=${0x44332211}
        Endian Check Packed to Unpacked    dev=${dev}    exp_data=${0x11223344}
    END

Registers - Write-Read Test
    FOR    ${i}    IN RANGE    3
        Reg Wr Rd Test    dev=${dev}    num_p4_proc=${num_p4_proc}
    END
